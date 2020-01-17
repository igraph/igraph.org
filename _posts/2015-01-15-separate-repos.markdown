---
title: Repositories at GitHub
date: 2015-01-16
---

A couple of days ago we changed how we use GitHub for igraph
development. Our goal is to make igraph development more accessible, and
our build process simpler. Instead of using a common repository for
everything, we now use separate repos for the igraph C library, the R
package and the Python extension. The igraph.org website was already in a
separate repository, and we will also break up the R package, by putting
loosely coupled parts in their own packages and repositories.

Main igraph repositories now:

 * igraph C library: https://github.com/igraph/igraph
 * igraph R package: https://github.com/igraph/rigraph
 * python-igraph: https://github.com/igraph/python-igraph
 * igraphdata R package: https://github.com/igraph/igraphdata
 * igraph.org homepage: https://github.com/igraph/igraph.org
