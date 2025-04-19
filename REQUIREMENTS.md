Instructions to build the homepage
==================================

The igraph homepage is built using Jekyll. Install
[Jekyll](https://jekyllrb.com) if you don't have it yet. Further requirements
are listed below.

You need so install RubyGems using `gem install`.

The homepage itself will be built in `_site/`. The contents of `_site/` is exactly
the same as what is shown at `igraph.org`.

If you simply want to add new blog posts, change the layout of the site or do
anything that does not involve messing around with igraph's source code (like
generating docs for a new version), the only thing that you need to know is
that you can edit the Jekyll pages locally and then run the following command
to preview your changes after a clean checkout:

`bundle install && bundle exec jekyll serve`

where `bundle install` takes care of installing Jekyll locally.

If you need to modify the parts of the homepage that are related to the
_generated_ documentation, there are a few useful `make` commands that you
should know about:

* `make core` rebuilds the core parts of the homepage.

* `make c` rebuilds the parts related to the C library.

* `make python` rebuilds the parts related to the Python interface.

* `make r` rebuilds the parts related to the R interface.

When you are satisfied with your changes, commit everything (excluding the
generated HTML files of the homepage in `_site/`) and push it to Github. Github
Actions will then update igraph.org accordingly.

Requirements for building the C-related pages
---------------------------------------------

TODO

Requirements for building the Python-related pages
---------------------------------------------

* Python 2.x or 3.x
* `epydoc`
* `sphinx`
* `sphinx_bootstrap_theme`

The requirements are installed automatically by the Makefile if you have Python
on your system.

Requirements for building the R-related pages
---------------------------------------------

* `roxygen2`
* `devtools`
* `irlba`
* `pkgconfig`
* LaTeX (for PDF documentation generation

You can install these (except LaTeX) from R with `install.packages(...)`.

