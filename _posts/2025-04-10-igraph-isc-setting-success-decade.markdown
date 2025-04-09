---
title: Setting up igraph for success in the next decade
date: 2025-04-10
tags: r
---

_Cross-posted on the [cynkra blog](https://cynkra.com/blog/2025-03-17-igraph-isc-setting-success-decade/)._


One year ago, a small group of us at cynkra submitted a project proposal to the R Consortium's ISC, which got approved.
We are very grateful for this [support](https://r-consortium.org/all-projects/2024-group-1.html#setting-up-igraph-for-success-in-the-next-decade).
In this post we shall explain what the motivation for our project was, what we accomplished… and what we hope to work on next!

<!--more-->

## Why did igraph need some dedicated maintenance?

The first version of the igraph R package was published on CRAN in 2006.
Since then, the igraph C library that forms the core of the R package, and the R package itself, have been further developed and [widely used](https://schochastics.github.io/R4SNA/intro.html#the-base-packages).
Over the years, the R package has also accrued a bit of documentation debt and technical debt, that we wanted to tackle to set up igraph for success in the next decade.
Both aspects had the potential to simplify further updates of the package.

## Adopting the lifecycle system

To provide a more consistent interface, part of igraph functions or arguments are slowly but consistently being deprecated.
Some of them used to be deprecated using custom solutions or base R deprecations.
In contrast, now all deprecations happen through the lifecycle package.
On manual pages, deprecation badges indicate the maintenance status of functions or arguments.

```r
library("igraph")
#> 
#> Attaching package: 'igraph'
#> The following objects are masked from 'package:stats':
#> 
#>     decompose, spectrum
#> The following object is masked from 'package:base':
#> 
#>     union
g <- sample_gnp(10, 0.5)
graph.density(g)
#> Warning: `graph.density()` was deprecated in igraph 2.0.0.
#> ℹ Please use `edge_density()` instead.
#> This warning is displayed once every 8 hours.
#> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
#> generated.
#> [1] 0.5111111
```

Having everything in the "lifecycle system" now means the interface and documentation is consistent for users, and also that we can more easily increase deprecation levels over time by searching for lifecycle calls.
Last, but not least, all deprecations are listed in a [vignette](https://r.igraph.org/articles/current-deprecations.html).

## Documentation improvements

Besides the documentation of lifecycle, we created and used a custom roxygen2 tags to link to the C docs from manual pages.
[Example](https://r.igraph.org/reference/sample_sbm.html#related-documentation-in-the-c-library).

## Fewer errors, better errors

We have made a conscious effort to port errors from base R to cli, at the same time improving phrasing of errors.
For instance,

```r
stop("invalid value supplied for `weighted' argument, please see docs.")
```

became

```r
cli::cli_abort(c(
  "{.arg weighted} can't be {.obj_type_friendly {weighted}}.",
  i = "See {.help graph_from_biadjacency_matrix}'s manual page."
))
```

which is more informative about the invalid value supplied, and which directly links to the manual page.

We have also fixed some bugs ( [example](https://github.com/igraph/rigraph/pull/1716)).

## Work on the internals

We did a lot of refactoring!
Most of it was focussed on [tests](https://github.com/igraph/rigraph/pulls?q=sort%3Aupdated-desc+is%3Apr+in%3Atitle+%22test%3A%22+is%3Amerged), as [previously explained on this blog](/posts/2025-03-04-refactoring-test-files/): merging some test files to ensure alignment between R scripts and test files, refactoring test files for better readability and future debugging, updating the testthat usage by removing old expectations.
We also worked in the `R/`folder, for instance we replaced the usage of an embedded version of lazyeval with rlang calls.
( [PR 1](https://github.com/igraph/rigraph/pull/1441), [PR 2](https://github.com/igraph/rigraph/pull/1445))

## Sharing our experience

We shared our experience working on igraph in part of a talk and in various blog posts:

- useR! 2024 keynote talk [How your code might get rusty, and what you can do about it](https://masalmon.eu/talks/2024-07-10-user-2024-rusty-code/) -- it presented our work on igraph.
- Blog post [Automate code refactoring with {xmlparsedata} and {brio}](https://masalmon.eu/2024/05/15/refactoring-xml/) -- how we replaced some old testthat's expectations with new ones, using a script rather than manually.
- Blog post [What I edit when refactoring a test file](https://masalmon.eu/2024/05/23/refactoring-tests/) -- some rules for more readable test files, like putting expectations closer to the values they tackle.
- Blog post [Extracting names of functions defined in a script with treesitter](https://masalmon.eu/2024/07/18/extract-function-names-treesitter/) -- how we used a script to get a list of functions we needed to create.
- Blog post [Create and use a custom roxygen2 tag](https://masalmon.eu/2024/09/03/roxygen2-custom-tag/) -- how we created a custom roxygen2 tag to link to C docs from manual pages.
- Blog post [Cover and modify, some tips for R package development](https://masalmon.eu/2024/09/24/cover-modify-r-packages/) -- how we go about adding new tests.
- Blog post [Organizing tests in R packages](https://blog.cynkra.com/posts/2025-03-04-refactoring-test-files/) -- why and how we improved test organization in igraph.

## Conclusion

We are proud of the progress made in the igraph codebase but we don't want to stop here!
In particular, we'd really like to do more work on open issues to improve the state of the issue tracker and to ensure easier future triage ; to better describe and execute the scope differences between the C and R libraries ; and to make the documentation more complete and clearer.