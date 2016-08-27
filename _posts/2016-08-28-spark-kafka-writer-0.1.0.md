---
layout: post
title: spark-kafka-writer v0.1.0 released!
categories:
  - Spark
  - Kafka
  - tutorial
---

Spark Kafka writer is a little project that lets you save your Spark RDDs and
DStreams to Kafka seamlessly.

The sources are available on
[GitHub](https://github.com/BenFradet/spark-kafka-writer) and the first version
is available on [maven central](
http://search.maven.org/#search%7Cga%7C1%7Ca%3Aspark-kafka-writer_*)

If you've already heard about this project it's because I took over the work of
[Hari Shreedharan](https://github.com/harishreedharan) since his project
was discontinued for reasons unknown to me.

I released the first version (0.1.0) a couple of weeks back and we've used it
until now without issues so I thought I'd write a bit about how to use it.

Important note: the 0.1.0 relase is compatible with Apache Spark 1.6.x and
hasn't been tested against 2.0.0.

### Dependency

The first thing you'll have to do is to add a dependency to the project.

- if you're using sbt:

{% highlight scala %}
libraryDependencies ++= Seq(
  "com.github.benfradet" %% "spark-kafka-writer" % "0.1.0"
)
{% endhighlight %}

- if you're using maven:

{% highlight xml %}
<dependencies>
    <dependency>
        <groupId>com.github.benfradet</groupId>
        <artifactId>spark-kafka-writer_${scala.binary.version}</artifactId>
        <version>0.1.0</version>
    </dependency>
</dependencies>
{% endhighlight %}

### Writing an RDD to Kafka

If you'd like to write an RDD to Kafka it's pretty simple.

First, you'll have to define a configuration for your Kafka producer:

{% highlight scala %}
import org.apache.kafka.common.serialization.StringSerializer

val producerConfig = {
  val p = new java.util.Properties()
  p.setProperty("bootstrap.servers", "127.0.0.1:9092")
  p.setProperty("key.serializer", classOf[StringSerializer].getName)
  p.setProperty("value.serializer", classOf[StringSerializer].getName)
  p
}
{% endhighlight %}

This is the minimum set of properties you'll have to provide. A full list of
the available properties can be found [here](
http://kafka.apache.org/documentation.html#producerconfigs).

Next up, you can just write your RDD to Kafka!

{% highlight scala %}
import com.github.benfradet.spark.kafka.writer.KafkaWriter._

val rdd: RDD[String] = ...
rdd.writeToKafka(
  producerConfig,
  s => new ProducerRecord[String, String]("my-topic", s)
)
{% endhighlight %}

The first argument to the `writeToKafka` function is our previously defined
producer configuration.

The second argument is a function which transforms an element of the RDD (here
a `String`) into a `ProducerRecord` which can be sent to Kafka. Here, we
simply create a producer record with the topic we want to send our messages to
(`my-topic`) and the record will only contain a value which is our RDD element.

If you want to know more about `ProducerRecord`, the javadoc can be found
[here](http://kafka.apache.org/0100/javadoc/index.html?org/apache/kafka/clients/producer/ProducerRecord.html).

### Writing a DStream to Kafka

The API for writing a DStream to Kafka is very similar to the one we just used
to write RDDs.

In fact, we'll reuse the same configuration as before to write our DStream to
Kafka:

{% highlight scala %}
import com.github.benfradet.spark.kafka.writer.KafkaWriter._

val dStream: DStream[String] = ...
dStream.writeToKafka(
  producerConfig,
  s => new ProducerRecord[String, String]("my-topic", s)
)
{% endhighlight %}

As you can notice, the API is exactly the same!

### Future work

As mentioned earlier, the 0.1.0 version only supports Apache Spark 1.6.x.
Because of that, the current focus is to support Spark 2.0.0 with support for
both Kafka 0.8 and Kafka 0.10. This is planned for 0.2.0.

Another thing I'd like to work on is the ability to write DataFrames to Kafka
but that won't be in the near future I would think.

If you'd like to help out or fill a bug you've found, please pick or create an
issue on [GitHub](https://github.com/benfradet/spark-kafka-writer/issues)!

You can also discuss the project on the
[Gitter channel](https://gitter.im/BenFradet/spark-kafka-writer).
