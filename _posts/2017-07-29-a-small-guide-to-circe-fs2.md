---
layout: post
title: A small guide to circe-fs2
categories:
  - circe
  - fs2
  - tutorial
---

This is a small blog post on [circe-fs2](https://github.com/circe/circe-fs2), a small library for
streaming, using [fs2](https://github.com/functional-streams-for-scala/fs2/), JSON parsing and
decoding, using [circe](https://github.com/circe/circe).

Since the documentation is a bit scarce, I put together a small guide to keep people from having to
check out the source code.

### Setup

For the purpose of the tutorial, let's say that we have the following `popularity.json` file:

{% highlight json %}
[
  {
    "repo": "circe-fs2",
    "stars": 13
  },
  {
    "repo": "circe-yaml",
    "stars": 32
  }
]
{% endhighlight %}

which we wish to parse and decode as the following `Popularity` case class:

{% highlight scala %}
case class Popularity(repo: String, stars: Int)
{% endhighlight %}

### Parsing

circe-fs2 offers three different strategies to parse your stream of JSONs depending on the type of
your input stream.

#### `Stream[F[_], String]`

If you have a stream of strings you can parse it using `stringParser`:

{% highlight scala %}
val stringStream: Stream[Task, String] =
  io.file.readAll[Task](Paths.get("popularity.json"), 4096)
    .through(text.utf8Decode)

val parsedStream: Stream[Task, Json] =
  stringStream.through(stringParser)
{% endhighlight %}

#### `Stream[F[_], Byte]`

If you have a stream of bytes, you can rely on `byteParser`:

{% highlight scala %}
val byteStream: Stream[Task, Byte] =
  io.file.readAll[Task](Paths.get("popularity.json"), 4096)

val parsedStream: Stream[Task, Json] =
  byteStream.through(byteParser)
{% endhighlight %}

Note that this parser hasn't been published yet, you'll have to compile circe-fs2 from source if
you want to use it.

#### `Stream[F[_], Chunk[Byte]]`

Finally, if you have a stream of chunked bytes, you can use `byteParserC`:

{% highlight scala %}
val byteCStream: Stream[Task, Chunk[Byte]] =
  io.file.readAll[Task](Paths.get("popularity.json"), 4096)
    .through(pipe.chunks)

val parsedStream: Stream[Task, Json] =
  byteCStream.through(byteParserC)
{% endhighlight %}

We now have a `Stream[F[_]], Json]`, where `Json` is Circe's way of representing a JSON.

### Decoding

Now that we have a stream of `Json`s, we can rely on circe-generic to automatically derive a
`Decoder` for our `Popularity` case class and turn our stream into a `Stream[F[_], Popularity]`:

{% highlight scala %}
val popularityStream: Stream[Task, Popularity] =
  parsedStream.through(decoder[Task, Popularity])
{% endhighlight %}

We can now run our stream:

{% highlight scala %}
println(popularityStream.runLog.unsafeAttemptRun())
{% endhighlight %}

### Conclusion

I hope this introduction proved useful.

You can find a full gist at <https://gist.github.com/BenFradet/a69e3fa86ad2654ed017e2cb2881c307>.
