---
layout: post
title: Using k-nearest neighbors to diagnose cancer
categories:
    - machine learning
    - tutorial
    - R
---

In this post, I will walk you through an application of
[the k-nearest neighbors algorithm](http://en.wikipedia.org/wiki/K-nearest_neighbors_algorithm)
to diagnose breast cancer.

In order to follow along, you will need [R](http://www.r-project.org/) installed
along with a couple of packages:

  - [class](http://cran.r-project.org/web/packages/class/index.html) which
contains various functions related to classification and notably the `knn`
function
  - [gmodels](http://cran.r-project.org/web/packages/gmodels/index.html) which
will be useful to us towards the end of this post when we will want to evaluate
the performance of our algorithm with the `CrossTable` function.


As a reminder, you can install a package in R with the following command:

{% highlight R %}
install.packages("name_of_the_package")
{% endhighlight %}

We will also need a dataset to apply the k-nearest neighbors algorithm. I chose
[the popular breast cancer data set](http://archive.ics.uci.edu/ml/datasets/Breast+Cancer+Wisconsin+%28Diagnostic%29)
which is publicy available and comes from [the repository of machine learning
datasets of UCI](http://archive.ics.uci.edu/ml)

You can find the code for this post on
[GitHub](https://github.com/BenFradet/kNNPost).

<br>

### Data exploration and data transformation
<br>

#### Getting to know the dataset without R

Without doing any R programming, you can learn a lot from the dataset by reading
[the document presenting it](http://archive.ics.uci.edu/ml/machine-learning-databases/breast-cancer-wisconsin/wdbc.names).

For example, you can learn the names of the different features and what they
represent, the total number of examples and how they are split between benign
and malignant, etc.

We learn that there are actually 10 numeric features which are measured for each
cell nucleus and for each of these features the mean, the standard error and
the largest (or "worst") are stored in the dataset.

Another useful nugget of information in this document is that there are no
missing attribute values in the dataset so we won't have to do much data
transformation which is great.

#### Adding the names of the features in the dataset

One thing you will notice when downloading [the dataset](http://archive.ics.uci.edu/ml/machine-learning-databases/breast-cancer-wisconsin/wdbc.data)
is that there are no header lines in the CSV file.

Personally, I don't like naming features in R and since the number of features
(32) is manageable, I added the names of the features directly in the CSV file.

Consequently, the first line becomes:

{% highlight text %}
id,diagnosis,radius_mean,texture_mean,perimeter_mean,area_mean,smoothness_mean,
compactness_mean,concavity_mean,concave_point_mean,symmetry_mean,
fractal_dimension_mean,radius_se,texture_se,perimeter_se,area_se,smoothness_se,
compactness_se,concavity_se,concave_point_se,symmetry_se,fractal_dimension_se,
radius_largest,texture_largest,perimeter_largest,area_largest,smootness_largest,
compactness_largest,concavity_largest,concave_point_largest,symmetry_largest,
fractal_dimension_largest
{% endhighlight %}

The modified dataset can be found on [GitHub](https://github.com/BenFradet/kNNPost/blob/master/wdbc.data).

#### Reading data into R

We are now ready to load the data into R:

{% highlight R %}
wdbc <- read.csv('wdbc.data', stringsAsFactors = FALSE)
{% endhighlight %}

As you may have noticed from the dataset or the names of the features, there is
an `id` column in the dataset and since it doesn't contain any information it
should be removed from the dataset.

{% highlight R %}
wdbc <- wdbc[-1]
{% endhighlight %}

We will also need to transform our `diagnosis` feature which contains "B" or "M"
depending on whether the cancer was benign or malignant into a factor to be able
to use the `knn` function later.

{% highlight R %}
wdbc$diagnosis <- factor(wdbc$diagnosis, levels = c('B', 'M'),
    labels = c('Benign', 'Malignant'))
{% endhighlight %}

#### Random permutation

Another thing we will need to is to randomly permute our examples in order to
avoid any kind of ordering which might be already present in the dataset. This
is important because if the dataset were ordered by diagnosis for example and if
we were to split our dataset between a training set and a test set, the test set
would be filled by either only benign or malignant tumors to which the algorithm
wouldn't have been confronted against during the training phase.

{% highlight R %}
wdbc <- wdbc[sample(nrow(wdbc)), ]
{% endhighlight %}

#### Features scaling

If you have a look at the range of the different mean features with:

{% highlight R %}
> lapply(wdbc[2:11], function(x) { max(x) - min(x) })
$radius_mean
[1] 21.129

$texture_mean
[1] 29.57

$perimeter_mean
[1] 144.71

$area_mean
[1] 2357.5

$smoothness_mean
[1] 0.11077

$compactness_mean
[1] 0.32602

$concavity_mean
[1] 0.4268

$concave_point_mean
[1] 0.2012

$symmetry_mean
[1] 0.198

$fractal_dimension_mean
[1] 0.04748
{% endhighlight %}

You can see that there are ranges of features which are 1000 times bigger than
others, this is a problem because since the kNN algorithm relies on distance
measurement it will give more importance to features with larger values.

In order to prevent our algorithm from giving too much importance a few
feature, we will need to normalize them. One way to do so is to use the `scale`
function:

{% highlight R %}
wdbcNormalized <- as.data.frame(scale(wdbc[-1]))
{% endhighlight %}

You can check that the means of every feature is null now:

{% highlight R %}
summary(wdbcNormalized[c('radius_mean', 'area_worst', 'symmetry_se')])
{% endhighlight %}

#### Splitting the dataset in two: training and test sets

We will have to split our dataset in order to train our algorithm (training set)
and then evaluate its performance (test set).

A good rule of thumb is to take 75% of the dataset for the training and leave
the rest as a test set.
We learned from [the dataset description](http://archive.ics.uci.edu/ml/machine-learning-databases/breast-cancer-wisconsin/wdbc.names)
that there were 569 examples in our dataset, so we'll take the first 427
examples as our training set and the last 142 as our test set.

{% highlight R %}
wdbcTraining <- wdbcNormalized[1:427, ]
wdbcTest <- wdbcNormalized[428:569, ]
{% endhighlight %}

We will also need the diagnosis feature as a separate factor in order to use the
`knn` function which we'll use later in this post.

{% highlight R %}
wdbcTrainingLabels <- wbdc[1:427, 1]
wdbcTestLabels <- wdbc[428:569, 1]
{% endhighlight %}

<br>

### Running kNN

We are now ready to use the `knn` function contained in the `class` package.
The function takes four arguments:

  - `train` which is our training set
  - `test` the training set
  - `class` which should be a factor containing the class for the training set
  - `k` the number of nearest neighbors to consider in order to predict the
class of a new example

#### Choosing the parameter k
