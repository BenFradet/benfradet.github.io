---
layout: post
title: OSS GitHub organizations monitoring
categories:
  - http4s
  - scala-js
---

For the past couple of years I've been working on and off on
[Dashing](https://github.com/BenFradet/dashing/graphs/contributors), it's a set of
dashboards to monitor an open source organization's health on GitHub.

At the moment, it mines historical data on GitHub regarding stars and pull requests.
Let's go through each dashboard!

### Dashboards

The hero repository dashboard display the evolution of the number of stars along a time
axis for a particular repository that you consider to be the "main" repository for your
organization.

Here, we can see the evolution of the popularity of [`hashicorp/terraform`](https://github.com/hashicorp/terraform):

![](/images/hero-repo.png)

The next dashboard show the evolution of the number of stars for the following `n` repositories in
terms of popularity and aggregates the other repositories.

Here, we can see the evolution of the popularity of the 5 most popular repositories in the
`hashicorp` organization: `consul`, `nomad`, `vault`, `vagrant` and `packer`. `terraform` is
excluded as we considered it to be the hero repository.

![](/images/topn-repos.png)

The other two dashboards focus on actual contributions by measure the number of pull
requests opened by people outside the organization across multiple organizations.

The first one does so quartlery. Here, we explore the pull requests opened by people
outside the Snowplow organizations: [snowplow](https://github.com/snowplow/),
[snowplow-incubator](https://github.com/snowplow-incubator/) and
[snowplow-referer-parser](https://github.com/snowplow-referer-parser/).

![](/images/prs-quarterly.png)

The same data is also available monthly.

![](/images/prs-monthly.png)

### Stack

### Running

### Conclusion

Of course, the set of dashboards is, at the moment, quite limited. Future dashboards
could include pull requests response and merge times and statistics around issues which
haven't been explored yet.

Dashing was originally meant to be a toy project to try out
[Scala.js](https://www.scala-js.org/) because I had never done any frontend development
before (as the project shows), there is a lot that can be improved in that regard.

As a result, I would gladly welcome any contributions on frontend-related improvements (of
course any improvement will still be definitely welcome!).

