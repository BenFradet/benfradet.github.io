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
<br>

### Data exploration and data transformation
<br>

#### Getting to know the Titanic dataset

You can find a description of the features on [Kaggle](https://www.kaggle.com/c/titanic/data).

The dataset is split into `train.csv` and `test.csv`. As you've probably already
assumed, `train.csv` will contain labeled data (the `Survived` column will be
filled) and `test.csv` will be unlabeled data. The goal is to predict for each
example/passenger in `test.csv` whether or not she/he survived.

#### Reading the Titanic dataset into Spark

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
