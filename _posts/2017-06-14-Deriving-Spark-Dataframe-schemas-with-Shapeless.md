---
layout: post
title: Deriving Spark Dataframe schemas with Shapeless
categories:
  - Spark
  - Scala
  - tutorial
---

A few months back I bought the excellent [Type Astronaut's Guide to Shapeless](
http://underscore.io/books/shapeless-guide/) which is, as its name implies, a comprehensive guide
to [Shapeless](https://github.com/milessabin/shapeless): a Scala library making it easier to do
generic programming.

A big part of the book is a practical tutorial on building a JSON encoder. As I read through this
example, I was eager to find a similar usecase where I could apply all this Shapeless knowledge.

By the end of the book, I came up with the idea of deriving instances of [Spark's StrucType](
http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.types.StructType).

### What are StructTypes?

`StructType` is the way Spark internally represents DataFrame schemas:

{% highlight scala %}
case class Foo(a: Int, b: String)

val df = spark.createDataFrame(Seq(Foo(1, "a"), Foo(2, "b")))
// df: DataFrame = [a: int, b: string]

df.schema
// res0: StructType = StructType(StructField(a,IntegerType,false), StructField(b,StringType,true))
{% endhighlight %}

The problem is interacting with them.

### The problem

When reading a DataFrame/Dataset from an external data source the schema, unless specified, has to
be inferred.

This is especially the case when reading:

- JSON (c.f. [JsonInferSchema](https://github.com/apache/spark/blob/master/sql/core/src/main/scala/org/apache/spark/sql/execution/datasources/json/JsonInferSchema.scala))
- CSV (c.f. [CSVInferSchema](https://github.com/apache/spark/blob/master/sql/core/src/main/scala/org/apache/spark/sql/execution/datasources/csv/CSVInferSchema.scala))

As shown in the code linked above, inferring the schema for your DataFrame translates into looking
at every record of all the files we need to read and coming up with a schema that can satisfy every
one of these rows (basically the disjunction of all the possible schemas).

As the benchmarks at the end of this post will show, this is a time consuming task which can be
avoided by specifying the schema in advance:

{% highlight scala %}
case class Foo(a: Int, b: String)

val schema = StructType(
  StructField("a", IntegerType) ::
  StructField("b", StringType) :: Nil
)

val df = spark
  .read
  .schema(schema)
  .json("/path/to/*.json")
  .as[Foo]
{% endhighlight %}

However, writing schemas again and again in order to avoid having Spark infer them is a lot of
tedious boilerplate, especially when dealing with complex domain-specific data models.

That's where [struct-type-encoder](https://github.com/benfradet/struct-type-encoder) comes into
play.

### The solution

`struct-type-encoder` provides a boilerplate-free way of specifying a `StructType` when reading a
DataFrame:

{% highlight scala %}
import ste._
val df = spark
  .read
  .schema(StructTypeEncoder[Foo].encode)
  .json("/path/to/*.json")
  .as[Foo]
{% endhighlight %}

### Under the hood

In this section, I'll detail the few lines of code behind the project.

The first step is to define a `DataTypeEncoder` type class which will be responsible of the mapping
between Scala types and [Spark DataTypes](
http://spark.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.types.package).

{% highlight scala %}
sealed trait DataTypeEncoder[A] {
  def encode: DataType
}

object DataTypeEncoder {
  def apply[A](implicit enc: DataTypeEncoder[A]): DataTypeEncoder[A] = enc

  def pure[A](dt: DataType): DataTypeEncoder[A] =
    new DataTypeEncoder[A] { def encode: DataType = dt }
}
{% endhighlight %}

We can now define a couple of primitive instances, e.g. for `Int` and `String`:

{% highlight scala %}
implicit val intEncoder: DataTypeEncoder[Int]       = pure(IntegerType)
implicit val stringEncoder: DataTypeEncoder[String] = pure(StringType)
{% endhighlight %}

and a couple of combinator instances:

{% highlight scala %}
implicit def encodeTraversableOnce[A0, C[_]](
  implicit
  enc: DataTypeEncoder[A0],
  is: IsTraversableOnce[C[A0]] { type A = A0 }
): DataTypeEncoder[C[A0]] =
  pure(ArrayType(enc.encode))

implicit def mapEncoder[K, V](
  implicit
  kEnc: DataTypeEncoder[K],
  vEnc: DataTypeEncoder[V]
): DataTypeEncoder[Map[K, V]] =
  pure(MapType(kEnc.encode, vEnc.encode))
{% endhighlight %}

Credit to [circe](https://github.com/circe/circe/blob/master/modules/core/shared/src/main/scala/io/circe/Encoder.scala#L342-L358)
for the collection encoder.

The second step is to derive `StructType`s from case classes leveraging Shapeless' `HList`s:

{% highlight scala %}
sealed trait StructTypeEncoder[A] extends DataTypeEncoder[A] {
  def encode: StructType
}

object StructTypeEncoder {
  def apply[A](implicit enc: StructTypeEncoder[A]): StructTypeEncoder[A] = enc

  def pure[A](st: StructType): StructTypeEncoder[A] =
    new StructTypeEncoder[A] { def encode: StructType = st }
}
{% endhighlight %}

We can now define our instances for `HList`:

{% highlight scala %}
implicit val hnilEncoder: StructTypeEncoder[HNil] = pure(StructType(Nil))

implicit def hconsEncoder[K <: Symbol, H, T <: HList](
  implicit
  witness: Witness.Aux[K],
  hEncoder: Lazy[DataTypeEncoder[H]],
  tEncoder: StructTypeEncoder[T]
): StructTypeEncoder[FieldType[K, H] :: T] = {
  val fieldName = witness.value.name
  pure {
    val head = hEncoder.value.encode
    val tail = tEncoder.encode
    StructType(StructField(fieldName, head) +: tail.fields)
  }
}

implicit def genericEncoder[A, H <: HList](
  implicit
  generic: LabelledGeneric.Aux[A, H],
  hEncoder: Lazy[StructTypeEncoder[H]]
): StructTypeEncoder[A] =
  pure(hEncoder.value.encode)
{% endhighlight %}

And that's it! We can now map case classes to `StructType`s.

### Benchmarks

I wanted to measure how much time was saved specifying the schema using struct-type-encoder compared
to letting Spark infer it.

In order to do so, I wrote a couple of benchmarks using [JMH](
http://openjdk.java.net/projects/code-tools/jmh/): one for JSON and one for CSV. Each of these
benchmarks writes a thousand file containing a hundred lines each and measure the time spent reading
the `Dataset`.

The following table sums up the results I gathered:

|   | derived | inferred |
|:-:|:-:|:-:|
| CSV  | 5.936 ± 0.035 s | 6.494 ± 0.209 s |
| JSON | 5.092 ± 0.048 s | 6.019 ± 0.049 s |

As we can see, bypassing the schema inference done by Spark using struct-type-encoder takes
16.7% less time when reading JSON and 8.98% less when reading CSV.

The code for the benchmarks can be found [here](https://github.com/BenFradet/struct-type-encoder/blob/master/benchmarks/src/main/scala/ste/benchmarks.scala).

They can be run using the dedicated sbt plugin [sbt-jmh](
https://github.com/ktoso/sbt-jmh) with the `jmh:run .*Benchmark` command.

### Get the code

If you'd like to use struct-type-encoder it's available on maven-central as
`"com.github.benfradet" %% "struct-type-encoder" % "0.1.0"`.

The repo can be found on github: <https://github.com/BenFradet/struct-type-encoder/>.

### Conclusion

Before reading [Dave Gurnell's book](http://underscore.io/books/shapeless-guide/), I had heard about
Shapeless but never really felt the need to dig deeper. This small project really made me understand
the value that Shapeless brings to the table.

About half-way through the project, I discovered [frameless](
https://github.com/typelevel/frameless), a library which aims to bring back type safety to Spark
SQL. It turns out that they use a similar mechanism in [TypedEncoder](https://github.com/typelevel/frameless/blob/502fcd8466c626fdcb39bf1d72beddc569c11b29/dataset/src/main/scala/frameless/TypedEncoder.scala).
The goal now is to expose the functionality proposed by struct-type-encoder in frameless.

Additionally, for 0.2.0, I want to start experimenting with coproducts and see what's possible
on Spark's side of things.
