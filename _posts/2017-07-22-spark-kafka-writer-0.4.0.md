---
layout: post
title: spark-kafka-writer v0.4.0 released!
categories:
  - Spark
  - Kafka
  - tutorial
---

We're pleased to announce version 0.4.0 of [Spark Kafka Writer](
https://github.com/benfradet/spark-kafka-writer).

Spark Kafka Writer is a library that lets tou save your Spark data to Kafka seamlessly: `RDD`s,
`DStream`s, `Dataset`s and `DataFrame`s.

The repository is on [GitHub](https://github.com/benfradet/spark-kafka-writer)
and you can find the latest version on [maven central](
http://search.maven.org/#search|ga|1|spark-kafka-writer).

In this post, we'll walk through the new support for writing `DataFrame`s and `Dataset`s to Kafka.

### Writing a DataFrame to Kafka

From version 0.4.0 on, you'll be able to write `DataFrame`s to Kafka.
This differs from [writing the output of batch queries to Kafka using the Structure Streaming API](
http://spark.apache.org/docs/latest/structured-streaming-kafka-integration.html#writing-the-output-of-batch-queries-to-kafka),
in the way that you control how you serialize `Row`s and you can access the callback API.

{% highlight scala %}
import com.github.benfradet.spark.kafka.writer._
import org.apache.kafka.clients.producer.{Callback, ProducerRecord, RecordMetadata}
import org.apache.kafka.common.serialization.StringSerializer

@transient lazy val log = org.apache.log4j.Logger.getLogger("spark-kafka-writer")

val producerConfig = Map(
  "bootstrap.servers" -> "127.0.0.1:9092",
  "key.serializer" -> classOf[StringSerializer].getName,
  "value.serializer" -> classOf[StringSerializer].getName
)

val dataFrame: DataFrame = ...
dataFrame.writeToKafka(
  producerConfig,
  row => new ProducerRecord[String, String](topic, row.toString),
  Some(new Callback with Serializable {
    override def onCompletion(metadata: RecordMetadata, e: Exception): Unit = {
      if (Option(e).isDefined) {
        log.warn("error sending message", e)
      } else {
        log.info(s"everything went fine, record offset was ${metadata.offset()}")
      }
    }
  })
)
{% endhighlight %}

### Writing a Dataset to Kafka

In the same way you can write `DataFrame`s to Kafka, you'll now be able to write `Dataset`s to
Kafka:

{% highlight scala %}
case class Foo(a: Int, b: String)

val dataset: Dataset[Foo] = ...
dataset.writeToKafka(
  producerConfig,
  foo => new ProducerRecord[String, String](topic, foo.toString),
  Some(new Callback with Serializable {
    override def onCompletion(metadata: RecordMetadata, e: Exception): Unit = {
      if (Option(e).isDefined) {
        log.warn("error sending message", e)
      } else {
        log.info(s"everything went fine, record offset was ${metadata.offset()}")
      }
    }
  })
)
{% endhighlight %}

### Other updates

Version 0.4.0 also brings other changes:

- Supporting Spark 2.2.0
- Providing a way to close producers (see [pull request #77](https://github.com/BenFradet/spark-kafka-writer/pull/77))
- Dropping the support for Kafka 0.8

### Roadmap

For version 0.5.0, we're aiming to provide a native API for Java and Python.

If you'd like to get involved, there are different ways you can contribute to
the project:

- [Give it a star](https://github.com/benfradet/spark-kafka-writer)
- [Create an issue](https://github.com/benfradet/spark-kafka-writer/issues)
- [Pick an issue labeled ready](https://github.com/benfradet/spark-kafka-writer/issues?q=is%3Aopen+is%3Aissue+label%3Aready)

You can also ask questions and discuss the project on [the Gitter channel](
https://gitter.im/benfradet/spark-kafka-writer) and check out [the Scaladoc](
https://benfradet.github.io/spark-kafka-writer/#package).
