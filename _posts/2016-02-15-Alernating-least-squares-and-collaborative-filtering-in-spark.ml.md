---
layout: post
title: Alternating least squares and collaborative filtering in spark.ml
categories:
  - machine learning
  - tutorial
  - Spark
---

In this post, I'll show you how to use alternating least squares (ALS for short)
in [spark.ml](http://spark.apache.org/docs/latest/ml-guide.html).

*Disclaimer: This post is mostly a copy/paste from
[a pull request](https://github.com/apache/spark/pull/10411) I wrote for Spark
documenting ALS and collaborative filtering in general in spark.ml.
Since the PR will likely be incorporated in the 2.0 release which is still a few
months away, I thought I'd share it. This is also in response to this
[stackoverflow question](http://stackoverflow.com/questions/35219854/where-to-find-spark-ml-dataframe-implements-about-collaborative-filtering) asking about documentation
regarding collaborative filtering in spark.ml.*

### Collaborative filtering 

[Collaborative filtering](http://en.wikipedia.org/wiki/Recommender_system#Collaborative_filtering)
is commonly used for recommender systems.  These techniques aim to fill in the
missing entries of a user-item association matrix.  `spark.ml` currently supports
model-based collaborative filtering, in which users and products are described
by a small set of latent factors that can be used to predict missing entries.
`spark.ml` uses the [alternating least squares
(ALS)](http://dl.acm.org/citation.cfm?id=1608614)
algorithm to learn these latent factors. The implementation in `spark.ml` has the
following parameters:

* *numBlocks* is the number of blocks the users and items will be partitioned into in order to parallelize computation (defaults to 10).
* *rank* is the number of latent factors in the model (defaults to 10).
* *maxIter* is the maximum number of iterations to run (defaults to 10).
* *regParam* specifies the regularization parameter in ALS (defaults to 1.0).
* *implicitPrefs* specifies whether to use the *explicit feedback* ALS variant or one adapted for
  *implicit feedback* data (defaults to `false` which means using *explicit feedback*).
* *alpha* is a parameter applicable to the implicit feedback variant of ALS that governs the
  *baseline* confidence in preference observations (defaults to 1.0).
* *nonnegative* specifies whether or not to use nonnegative constraints for least squares (defaults to `false`).
<br><br>

#### Explicit vs. implicit feedback

The standard approach to matrix factorization based collaborative filtering treats 
the entries in the user-item matrix as *explicit* preferences given by the user to the item,
for example, users giving ratings to movies.

It is common in many real-world use cases to only have access to *implicit feedback* (e.g. views,
clicks, purchases, likes, shares etc.). The approach used in `spark.mllib` to deal with such data is taken
from [Collaborative Filtering for Implicit Feedback Datasets](http://dx.doi.org/10.1109/ICDM.2008.22).
Essentially, instead of trying to model the matrix of ratings directly, this approach treats the data
as numbers representing the *strength* in observations of user actions (such as the number of clicks,
or the cumulative duration someone spent viewing a movie). Those numbers are then related to the level of
confidence in observed user preferences, rather than explicit ratings given to items. The model
then tries to find latent factors that can be used to predict the expected preference of a user for
an item.
<br><br>

#### Scaling of the regularization parameter

We scale the regularization parameter `regParam` in solving each least squares problem by
the number of ratings the user generated in updating user factors,
or the number of ratings the product received in updating product factors.
This approach is named "ALS-WR" and discussed in the paper
"[Large-Scale Parallel Collaborative Filtering for the Netflix Prize](http://dx.doi.org/10.1007/978-3-540-68880-8_32)".
It makes `regParam` less dependent on the scale of the dataset, so we can apply the
best parameter learned from a sampled subset to the full dataset and expect similar performance.
<br><br>

### Examples
<br>

#### Scala example

In the following example, we load rating data from the
[MovieLens dataset](http://grouplens.org/datasets/movielens/), each row
consisting of a user, a movie, a rating and a timestamp.
We then train an ALS model which assumes, by default, that the ratings are
explicit (`implicitPrefs` is `false`).
We evaluate the recommendation model by measuring the root-mean-square error of
rating prediction.

Refer to the [`ALS` Scala docs](api/scala/index.html#org.apache.spark.ml.recommendation.ALS)
for more details on the API.

SCALA EXAMPLE

If the rating matrix is derived from another source of information (i.e. it is
inferred from other signals), you can set `implicitPrefs` to `true` to get
better results:

{% highlight scala %}
val als = new ALS()
  .setMaxIter(5)
  .setRegParam(0.01)
  .setImplicitPrefs(true)
  .setUserCol("userId")
  .setItemCol("movieId")
  .setRatingCol("rating")
{% endhighlight %}
<br><br>

#### Java example

In the following example, we load rating data from the
[MovieLens dataset](http://grouplens.org/datasets/movielens/), each row
consisting of a user, a movie, a rating and a timestamp.
We then train an ALS model which assumes, by default, that the ratings are
explicit (`implicitPrefs` is `false`).
We evaluate the recommendation model by measuring the root-mean-square error of
rating prediction.

Refer to the [`ALS` Java docs](api/java/org/apache/spark/ml/recommendation/ALS.html)
for more details on the API.

JAVA EXAMPLE

If the rating matrix is derived from another source of information (i.e. it is
inferred from other signals), you can set `implicitPrefs` to `true` to get
better results:

{% highlight java %}
ALS als = new ALS()
  .setMaxIter(5)
  .setRegParam(0.01)
  .setImplicitPrefs(true)
  .setUserCol("userId")
  .setItemCol("movieId")
  .setRatingCol("rating");
{% endhighlight %}
<br><br>

#### Python example

In the following example, we load rating data from the
[MovieLens dataset](http://grouplens.org/datasets/movielens/), each row
consisting of a user, a movie, a rating and a timestamp.
We then train an ALS model which assumes, by default, that the ratings are
explicit (`implicitPrefs` is `False`).
We evaluate the recommendation model by measuring the root-mean-square error of
rating prediction.

Refer to the [`ALS` Python docs](api/python/pyspark.ml.html#pyspark.ml.recommendation.ALS)
for more details on the API.

PYTHON EXAMPLE

If the rating matrix is derived from another source of information (i.e. it is
inferred from other signals), you can set `implicitPrefs` to `True` to get
better results:

{% highlight python %}
als = ALS(maxIter=5, regParam=0.01, implicitPrefs=True,
          userCol="userId", itemCol="movieId", ratingCol="rating")
{% endhighlight %}

- checks the links
- link to the gh repo
