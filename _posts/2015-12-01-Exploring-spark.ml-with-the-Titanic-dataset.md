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
into two: [spark.mllib] which is built on top of the old RDDs and [spark.ml]
which is built on top of the DataFrame API. In this blogpost, I'll talk
exclusively about spark.ml.

If you want to follow this tutorial you will have to down
