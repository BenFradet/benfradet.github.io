---
layout: post
title: spark-kafka-writer v0.2.0 released!
categories:
  - Spark
  - Kafka
  - tutorial
---

As a reminder, Spark Kafka writer is a project that lets you save your Spark
`RDD`s and `DStream`s to Kafka seamlessly.

The repo is on [GitHub](https://github.com/benfradet/spark-kafka-writer) and
you can find the latest version on [maven central](
http://search.maven.org/#search%7Cga%7C1%7Ca%3Aspark-kafka-*).

In this post, I'll introduce what's new and the breaking changes we've made.

### Support for Spark 2.0!

First and foremost, the 0.2.0 release is compatible with Spark 2.0 and is built
against it. Feel free to update the version of your Spark Kafka writer if you're
using Spark 2.0.

### Support for Kafka 0.8 and Kafka 0.10

Since support for Kafka is split inside Spark depending on whether you're using
Kafka 0.8 (`spark-streaming-kafka-0-8`) or Kafka 0.10
(`spark-streaming-kafka-0-10`), we did the same for spark-kafka-writer.

As a result, two artifacts have been created:

- if you're using Kafka 0.8:

{% highlight scala %}
libraryDependencies ++= Seq(
  "com.github.benfradet" %% "spark-kafka-0-8-writer" % "0.2.0"
)
{% endhighlight %}

- if you're using Kafka 0.10:

{% highlight scala %}
libraryDependencies ++= Seq(
  "com.github.benfradet" %% "spark-kafka-0-10-writer" % "0.2.0"
)
{% endhighlight %}

### Implicits moved to a top-level package object

In order to reduce the verbosity when using spark-kafka-writer, we decided
to move the definitions of the implicits needed to convert an `RDD` or a
`DStream` to our internal `KafkaWriter` to a top-level package object.

Consequently, you won't need to import
`com.github.benfradet.spark.kafka.writer.KafkaWriter._` as before, but only
`com.github.benfradet.spark.kafka.writer._`.

Following is a full example showing the new import using Kafka 0.10.

{% highlight scala %}
import com.github.benfradet.spark.kafka010.writer._
import org.apache.kafka.common.serialization.StringSerializer

val producerConfig = {
  val p = new java.util.Properties()
  p.setProperty("bootstrap.servers", "127.0.0.1:9092")
  p.setProperty("key.serializer", classOf[StringSerializer].getName)
  p.setProperty("value.serializer", classOf[StringSerializer].getName)
}

val rdd: RDD[String] = ...
rdd.writeToKafka(
  producerConfig,
  s => new ProducerRecord[String, String]("my-topic", s)
)

val dstream: DStream[String] = ...
dstream.writeToKafka(
  producerConfig,
  s => new ProducerRecord[String, String]("my-topic", s)
)
{% endhighlight %}

### Online Scaladoc

Starting from this release, the scaladoc is available online at
<https://benfradet.github.io/spark-kafka-writer>.

### Future work

Quite a few things are planned for 0.3.0:

- the ability to write the same message to multiple topics
- a way to send different messages to different topics
- APIs to write `DataFrame`s and `Dataset`s to Kafka

If you're interested in helping out, there are ways you can contribute to the
project:

- Give it a star on [GitHub](https://github.com/benfradet/spark-kafka-writer)
- If you've found a bug, create an issue on [Github](
https://github.com/benfradet/spark-kafka-writer/issues)
- If you'd like to contribute, you can pick [an issue labeled ready](
https://github.com/benfradet/spark-kafka-writer/issues?q=is%3Aopen+is%3Aissue+label%3Aready)

You can also ask your questions and discuss the project on the [Gitter channel](
https://gitter.im/benfradet/spark-kafka-writer).
