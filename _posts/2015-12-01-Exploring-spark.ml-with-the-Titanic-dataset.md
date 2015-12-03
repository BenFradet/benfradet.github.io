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
[Apache Spark](http://spark.apache.org/) and more particularly MLlib which is
the Spark submodule dedicated to machine learning. This submodule is split
into two: [spark.mllib](http://spark.apache.org/docs/latest/mllib-guide.html#mllib-types-algorithms-and-utilities)
which is built on top of the old RDDs and [spark.ml](http://spark.apache.org/docs/latest/mllib-guide.html#sparkml-high-level-apis-for-ml-pipelines)
which is built on top of the DataFrame API. In this post, I'll talk
exclusively about spark.ml.

If you want to follow this tutorial you will have to download spark which can
be done [here](http://spark.apache.org/downloads.html). Additionnally, you will
need a few dependencies in order to build your project:

| groupId           | artifactId        | version  | scope     |
| ----------------- |------------------ |----------|---------- |
| org.apache.spark  | spark-core_2.10   | 1.5.2    | provided  |
| org.apache.spark  | spark-sql_2.10    | 1.5.2    | compile   |
| org.apache.spark  | spark-mllib_2.10  | 1.5.2    | compile   |
| com.databricks    | spark-csv_2.10    | 1.2.0    | compile   |
