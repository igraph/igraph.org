Instructions to build the homepage
==================================

The igraph homepage is built using Jekyll. Install
[Jekyll](https://jekyllrb.com) if you don't have it yet. Further requirements
are listed below.

You need so install the following RubyGems (e.g. using `gem install`):
- `addressable-2.6.0`
- `bundler-2.1.4`
- `concurrent-ruby-1.1.5`
- `eventmachine-1.2.7`
- `ffi-1.10.0`
- `i18n-0.9.5`
- `rb-fsevent-0.10.3`
- `rb-inotify-0.10.0`
- `sass-listen-4.0.0`
- `sass-3.7.4`
- `ruby_dep-1.5.0`
- `jekyll-watch-2.2.1`
- `liquid-4.0.3`
- `pathutil-0.16.2`
- `safe_yaml-1.0.5`
- `jekyll-3.8.5`
- `jekyll-sitemap-1.3.1`
- `multi_json-1.13.1`
- `pygments.rb-1.2.1`

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

