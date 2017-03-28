---
layout: post
title: spark-kafka-writer v0.3.0 released!
categories:
  - Spark
  - Kafka
  - tutorial
---

We're pleased to announce version 0.3.0 of [Spark Kafka Writer](
https://github.com/benfradet/spark-kafka-writer).

Spark Kafka Writer is a library that lets tou save your Spark `RDD`s and
`DStream`s to Kafka seamlessly.

The repository is on [GitHub](https://github.com/benfradet/spark-kafka-writer)
and you can find the latest version on [maven central](
http://search.maven.org/#search|ga|1|spark-kafka-writer).

In this post we'll cover the new `Callback` API as well as the other small
updates this release brings.

### Callback API

The major update for this release is the possibility to have a Kafka `Callback`
called whenever a message is produced.

As an example, we could log a message whenever the production of a message
failed:

{% highlight scala %}
import com.github.benfradet.spark.kafka010.writer._
import org.apache.kafka.clients.producer.{Callback, ProducerRecord, RecordMetadata}

@transient lazy val log = org.apache.log4j.Logger.getLogger("spark-kafka-writer")

val producerConfig: java.util.Properties = ...

// with a RDD
val rdd: RDD[String] = ...
rdd.writeToKafka(
  producerConfig,
  s => new ProducerRecord[String, String](topic, s),
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

// with a DStream
val dStream: DStream[String] = ...
dStream.writeToKafka(
  producerConfig,
  s => new ProducerRecord[String, String](topic, s),
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

Refer to [the Kafka javadoc for sending a message with a Callback through the Kafka producer](http://kafka.apache.org/0102/javadoc/org/apache/kafka/clients/producer/KafkaProducer.html#send(org.apache.kafka.clients.producer.ProducerRecord,%20org.apache.kafka.clients.producer.Callback)) to know more about callbacks in Kafka.

Thanks a lot to [Lawrence Carvalho](https://github.com/lacarvalho91) for this
cool new feature!

### Other updates

Version 0.3.0 brings another couple of updates:

- Thanks to [phungleson](https://github.com/phungleson) who updated the Spark
version Spark Kafka Writer builds against to 2.1.0
- Thanks [Bas van den Brink](https://github.com/basvandenbrink) who caught a
nasty bug where Kafka producers were always recreated instead of cached (this
one's on me, should have copy/pasted :'()

### Roadmap

For version 0.4.0, we're aiming to provide an API to write DataFrams and
Datasets to Kafka.

If you'd like to get involved, there are different ways you can contribute to
the project:

- [Give it a star](https://github.com/benfradet/spark-kafka-writer)
- [Create an issue](https://github.com/benfradet/spark-kafka-writer/issues)
- [Pick an issue labeled ready](https://github.com/benfradet/spark-kafka-writer/issues?q=is%3Aopen+is%3Aissue+label%3Aready)

You can also ask questions and discuss the project on [the Gitter channel](
https://gitter.im/benfradet/spark-kafka-writer) and check out [the Scaladoc](
https://benfradet.github.io/spark-kafka-writer/#package).
