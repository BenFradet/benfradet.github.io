---
layout: post
title: Using K-means for image compression
categories:
    - how-to
    - Octave
---

I recently used [the K-means algorithm](http://en.wikipedia.org/wiki/K-means_clustering)
to reduce the number of colors I had in a picture to create a, what I think is,
pretty cool profile picture. In this post, I will show you how I managed to do
that.

What you will need is a not too large picture (otherwise the algorithm will take
much too long) and [Octave](http://www.gnu.org/software/octave/) installed which
is available on pretty much any Linux distributions.

The code is available on [GitHub](https://github.com/BenFradet/KMeansPost).

## Running K-means

I will split the process of running K-means in two different functions:

  - `initCentroids` will initialize random centroids from pixels in the image
  - `runKmeans` will actually run the K-means algorithm

If you're familiar with the K-means algorithm you know that the algorithm is
based on two steps and so the `runKmeans` will be calling two different
functions:

  - `assignCentroids` which will assign the closest centroid to each
example
  - `computeCentroids` which will compute new centroids from the assignments
done in `assignCentroids`
