Instructions to build the homepage
==================================

The igraph homepage is built using Jekyll. Install
[Jekyll](https://jekyllrb.com) if you don't have it yet. Further requirements
are listed below.

The homepage itself will be built in `docs/`. The contents of `docs/` is exactly
the same as what is shown at `igraph.org`. Instead of running Jekyll manually,
you should call:

* `make core` to rebuild the core parts of the homepage.

* `make c` to rebuild the parts related to the C library.

* `make python` to rebuild the parts related to the Python interface.

* `make r` to rebuild the parts related to the R interface.

When you are satisfied with your changes, commit everything (including the
generated HTML files of the homepage in `docs/`) and push it to Github. Github
Pages will then update igraph.org accordingly.

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

