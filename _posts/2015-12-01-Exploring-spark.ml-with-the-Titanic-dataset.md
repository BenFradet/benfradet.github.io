---
layout: post
title: Exploring spark.ml with the Titanic dataset
categories:
    - machine learning
    - tutorial
    - Spark
---

It's been a while since my last post, and in this post I'm going to talk about
a technology I've been using for almost a year now:
[Apache Spark](http://spark.apache.org/). Basically, Spark lets you do data
processing in a distributed manner. The project is subdivided in modules:

- Spark streaming which lets you interact with streams of data
- Spark SQL which aims to let you write SQL queries and execute them on your
    data
- MLlib, a machine learning library to train classification/regression models
    on your data (among other things)
- GraphX which provides an API to interact with graphs and graphs computation

Today, I'll talk about MLlib which is, as previously mentioned, the Spark
submodule dedicated to machine learning. This submodule is split
into two: [spark.mllib](http://spark.apache.org/docs/latest/mllib-guide.html#mllib-types-algorithms-and-utilities)
which is built on top of the old RDDs and [spark.ml](http://spark.apache.org/docs/latest/mllib-guide.html#sparkml-high-level-apis-for-ml-pipelines)
which is built on top of the DataFrame API. In this post, I'll talk
exclusively about spark.ml which aims to ease the process of creating machine
learning pipelines.

If you want to follow this tutorial you will have to download spark which can
be done [here](http://spark.apache.org/downloads.html). Additionnally, you will
need a few dependencies in order to build your project:

| groupId           | artifactId        | version  | scope     |
| ----------------- |------------------ |----------|---------- |
| org.apache.spark  | spark-core_2.10   | 1.5.2    | provided  |
| org.apache.spark  | spark-sql_2.10    | 1.5.2    | compile   |
| org.apache.spark  | spark-mllib_2.10  | 1.5.2    | compile   |
| com.databricks    | spark-csv_2.10    | 1.2.0    | compile   |
<br>

We'll be using the Titanic dataset taken from a
[Kaggle competition](https://www.kaggle.com/c/titanic). The goal is to predict
if a passenger survived from a set of features such as the class the passenger
was in, hers/his age or the fare the passenger paid to get on board.

You can find the code for this post on [Github](https://github.com/BenFradet/kaggle).
<br><br>

### Data exploration and data transformation
<br>

#### Getting to know the Titanic dataset

You can find a description of the features on [Kaggle](https://www.kaggle.com/c/titanic/data).

The dataset is split into `train.csv` and `test.csv`. As you've probably already
assumed, `train.csv` will contain labeled data (the `Survived` column will be
filled) and `test.csv` will be unlabeled data. The goal is to predict for each
example/passenger in `test.csv` whether or not she/he survived.
<br><br>

#### Loading the Titanic dataset

Since the data is in csv format, we'll use [spark-csv](https://github.com/databricks/spark-csv)
which will parse our csv data and give us back Dataframes.

To load the `train.csv` and `test.csv` file, I wrote the following function:

{% highlight scala %}
def loadData(
  trainFile: String,
  testFile: String,
  sqlContext: SQLContext
): (DataFrame, DataFrame) = {
  val nullable = true
  val schemaArray = Array(
    StructField("PassengerId", IntegerType, nullable),
    StructField("Survived", IntegerType, nullable),
    StructField("Pclass", IntegerType, nullable),
    StructField("Name", StringType, nullable),
    StructField("Sex", StringType, nullable),
    StructField("Age", FloatType, nullable),
    StructField("SibSp", IntegerType, nullable),
    StructField("Parch", IntegerType, nullable),
    StructField("Ticket", StringType, nullable),
    StructField("Fare", FloatType, nullable),
    StructField("Cabin", StringType, nullable),
    StructField("Embarked", StringType, nullable)
  )

  val trainSchema = StructType(schemaArray)
  val testSchema = StructType(schemaArray.filter(p => p.name != "Survived"))

  val csvFormat = "com.databricks.spark.csv"

  val trainDF = sqlContext.read
  .format(csvFormat)
  .option("header", "true")
  .schema(trainSchema)
  .load(trainFile)

  val testDF = sqlContext.read
  .format(csvFormat)
  .option("header", "true")
  .schema(testSchema)
  .load(testFile)

  (trainDF, testDF)
}
{% endhighlight %}

This function takes the paths to the `train.csv` and `test.csv` files as the two
first arguments and a `sqlContext` which will have been initialized beforehand
like so:

{% highlight scala %}
val sc = new SparkContext(new SparkConf().setAppName("Titanic"))
val sqlContext = new SQLContext(sc)
{% endhighlight %}

Although not mandatory, we define the schema for the data as it is the same
for both files except for the `Survived` column.

Then, we use [spark-csv](https://github.com/databricks/spark-csv) to load our
data.
<br><br>

#### Feature engineering

Next, we'll do a bit of feature engineering on this dataset.

If you have a closer look at the `Name` column, you probably see that there is
some kind of title included in the name such as "Sir", "Mr", "Mrs", etc.
I think it is a valuable piece of information and I think it can influence
whether someone survived or not, that's why I extracted it in its own column.

My first intuition was to extract this title with a regex with the help of a
UDF (for user-defined function):

{% highlight scala %}
val Pattern = ".*, (.*?)\\..*".r
val title: (String => String) = {
  case Pattern(t) => t
  case _ => ""
}
val titleUDF = udf(title)

val dfWithTitle = df.withColumn("Title", titleUDF(col("Name")))
{% endhighlight %}

Unfortunately, every passenger's name doesn't comply with this regex and I had
to face some noise. As a result, I just looked for the distinct titles produced
by my UDF
{% highlight scala %}dfWithTitle.select("Title").distinct(){% endhighlight %}
and adapted it a bit:

{% highlight scala %}
val Pattern = ".*, (.*?)\\..*".r
val titles = Map(
  "Mrs"    -> "Mrs",
  "Lady"   -> "Mrs",
  "Mme"    -> "Mrs",
  "Ms"     -> "Ms",
  "Miss"   -> "Miss",
  "Mlle"   -> "Miss",
  "Master" -> "Master",
  "Rev"    -> "Rev",
  "Don"    -> "Mr",
  "Sir"    -> "Sir",
  "Dr"     -> "Dr",
  "Col"    -> "Col",
  "Capt"   -> "Col",
  "Major"  -> "Col"
)
val title: ((String, String) => String) = {
  case (Pattern(t), sex) => titles.get(t) match {
    case Some(tt) => tt
    case None     =>
        if (sex == "male") "Mr"
        else "Mrs"
  }
  case _ => "Mr"
}
val titleUDF = udf(title)

val dfWithTitle = df.withColumn("Title", titleUDF(col("Name"), col("Sex")))
{% endhighlight %}

This UDF tries to match on the previously defined pattern `Pattern`. If the
regex matches we'll try to find the title in our `titles` map. Finally, if we
don't find it, we'll define the title based on the `Sex` column: "Mr" if "male",
"Mrs" otherwise.

I, then, wanted to represent the family size of each passenger with the help of
the `Parch` column (which represents the number of parents/children aboard the
Titanic) and the `SibSp` column which represents the number of siblings/spouses
aboard:

{% highlight scala %}
val familySize: ((Int, Int) => Int) = (sibSp: Int, parCh: Int) => sibSp + parCh + 1
val familySizeUDF = udf(familySize)
val dfWithFamilySize = df
  .withColumn("FamilySize", familySizeUDF(col("SibSp"), col("Parch")))
{% endhighlight %}

The family size UDF just does the sum of the `SibSp` and the `Parch` columns
plus one.
<br><br>

#### Handling NA values

You have two options when dealing with NA:

  - either drop them through:
    {% highlight scala %}df.na.drop(){% endhighlight %}
  - or fill them with default values with:
    {% highlight scala %}df.na.fill(){% endhighlight %}

After noticing that NA values were present in the `Age`, `Fare` and `Embarked`
columns, I chose to replace them:

  - with the average age for the `Age` column
  - with the average fare for the `Fare` column
  - with "S" for the `Embarked` column which represents Southampton

In order to do this, I calculated the average of the `Age` column like so:

{% highlight scala %}
val avgAge = trainDF.select("Age").unionAll(testDF.select("Age"))
  .agg(avg("Age"))
  .collect() match {
  case Array(Row(avg: Double)) => avg
  case _ => 0
}
{% endhighlight %}

Same thing for the `Fare` column. I, then, filled my dataset with those
averages:

{% highlight scala %}
val dfFilled = df.na.fill(Map("Fare" -> avgFare, "Age" -> avgAge)
{% endhighlight %}

Another option, which I won't cover here, is to train a regression model on the
`Age` column and use this model to predict the age for the examples where the
`Age` column is NA. Same thing goes for handling NA for the `Fare` column.

However, spark-csv treats NA strings as empty strings instead of NAs (this is a
known bug described [here](https://github.com/databricks/spark-csv/issues/86)).
This is why I coded a UDF which transforms empty strings in the `Embarked`
column to "S" for Southampton:

{% highlight scala %}
val embarked: (String => String) = {
  case "" => "S"
  case a  => a
}
val embarkedUDF = udf(embarked)
val dfFilled = df.withColumn("Embarked", embarkedUDF(col("Embarked")))
{% endhighlight %}

### Building the ML pipeline

What's very interesting about spark.ml compared to spark.mllib, aside from
dealing with DataFrames instead of RDDs, is the fact that you can build and tune
your own machine learning pipeline as we'll see in a bit.

There are two main concepts in `spark.ml` (extracted from the
[guide](http://spark.apache.org/docs/latest/ml-guide.html#main-concepts)):

  - `Transformers`, which are algorithms which transfrom a DataFrame into
another. For example, a machine learning model is a `Transformer` which
transforms DataFrames with features into DataFrames with predictions.
  - `Estimators`, which are algorithms which can be fit on a DataFrame to
produce a `Transformer`. For example, a learning algorithm is an `Estimator`
which trains on a DataFrame to produce a machine learning model (which is a
`Transformer`.

A pipeline is an ordered combination of `Transformers` and `Estimators`.

#### Description of our pipeline

In this post, we'll be training a random forest and since `spark.ml` can't
handle categorical features or labels unless they are indexed, our first job
will be to do just that.

Then, we'll assemble all our feature columns into one vector column because
every `spark.ml` machine learning algorithms expects that.

Once this is done, we can train our random forest as our data is in the expected
format.

Finally, we'll have to *unindex* our labels so they can be interpretable by
Kaggle.
