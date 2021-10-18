
all: jekyll

.PHONY: all core c r python jekyll devserver

# Default doc version
CVERSION?=0.9.4
RVERSION?=1.2.7
PYVERSION?=0.9.6

# Available versions
CVERSIONS?='0.9.0 0.9.4 master develop'
RVERSIONS?='1.2.3 1.2.4 1.2.5 1.2.6 1.2.7'
PYVERSIONS?='0.9.6 master develop'
PYCVERSIONS?='0.9.4 0.9.4 develop'

# FIXME: this is broken now
# optional variable so we can update the C docs without making a release
# CCOMMITHASH?=8bca587ad
# optional variable so we can update the Python docs without making a release
PYCOMMITHASH?=9bde4c29f

CREPO=https://github.com/igraph/igraph
RREPO=https://github.com/igraph/rigraph
PYREPO=https://github.com/igraph/python-igraph

######################################################################
## C stuff

C=_build/c

clean_c:
	rm -rf c/html c/pdf c/stamp
	rm -rf $(C)

c: core c/stamp

c/stamp: $(C)/build/doc/stamp
	mkdir -p c/pre
	cp -r $(C)/build/doc/html/* c/pre/
	python3 _tools/c_postprocess_html.py c/pre c/html $(CVERSIONS) $(CVERSION)
	rm -rf c/pre
	cp -r $(C)/build/doc/pdf c/
	touch $@

$(C)/build/doc/stamp: $(C)/stamp
	_tools/c_build_versioned.sh $(C) $(CVERSIONS)
	touch $@

$(C)/stamp:
	mkdir -p $(C)
	# Clone repo if not present
	[ ! -d $(C)/.git ] && \
		cd $(C) && \
		git clone $(CREPO) .
	touch $@

######################################################################
## R stuff

R=_build/r


clean_r:
	rm -rf r/pre r/html r/pdf
	rm -rf $(R)

r: core r/stamp

r/stamp: $(R)/stamp
	mkdir -p r/pre
	cp -r $(R)/build/doc/html/* r/pre/
	cp -r $(R)/build/doc/pdf r/
	mkdir -p r/html
	_tools/r_postprocess_html.sh r/pre r/html $(RVERSION)
	rm -rf r/pre
	touch r/stamp

$(R)/stamp:
	mkdir -p $(R)
	_tools/r_build_versioned.sh $(R) $(RVERSIONS) $(RVERSION)
	touch $@

######################################################################
## Python stuff

ARCHFLAGS=-Wno-error=unused-command-line-argument

PY=_build/python

clean_python:
	rm -rf python/api
	rm -rf python/tutorial
	rm -rf $(PY)

python: core python/api/stamp python/tutorial/stamp

python/api/stamp: $(PY)/doc/api/stamp
	rm -rf python/api
	mkdir -p python/api
	cp -r $(PY)/doc/api_versions/* python/api/
	_tools/py_postprocess_html_api.py python/api $(PYVERSION)
	touch $@

$(PY)/doc/api/stamp: $(PY)/stamp
	export ARCHFLAGS=$(ARCHFLAGS) && _tools/py_build_versioned_api.sh $(PY) $(PYVERSIONS) $(PYCVERSIONS)
	touch $@

python/tutorial/stamp: $(PY)/doc/tutorial/stamp
	rm -rf python/tutorial
	mkdir -p python/tutorial
	cp -r $(PY)/doc/tutorial/* python/tutorial/
	rm $@
	_tools/py_postprocess_html_tutorial.py python/tutorial $(PYVERSION)
	touch $@

$(PY)/doc/tutorial/stamp: $(PY)/stamp
	_tools/py_build_versioned_tutorial.sh $(PY) $(PYVERSIONS)
	touch $@

$(PY)/stamp:
	mkdir -p $(PY)
	# Clone repo if not present
	[ ! -d $(PY)/.git ] && \
		cd $(PY) && \
		git clone $(PYREPO) . && \
		git submodule update --init
	# Make virtual environment if not present
	[ ! -d $(PY)/.venv ] && \
		cd $(PY) && \
		python3 -m venv .venv && \
		.venv/bin/pip install epydoc pydoctor wheel Sphinx sphinxbootstrap4theme
	# Patch pydoctor until they fix it
	_tools/patch-pydoctor.sh $(PY)
	touch $@

######################################################################
## Core stuff

HTML= index.html news.html code-of-conduct.html \
      _layouts/default.html _layouts/r-manual.html _layouts/c-manual.html \
      c/index.html r/index.html python/index.html

CSS= css/affix.css css/manual.css css/other.css fonts/fonts.css

POSTS= $(wildcard _posts/*)

core: $(HTML) $(CSS) $(POSTS) vendor/bundle
	printf "$(CVERSION)" > _includes/igraph-cversion
	printf "$(RVERSION)" > _includes/igraph-rversion
	printf "$(PYVERSION)" > _includes/igraph-pyversion
	printf "$(CVERSIONS)" | tr -d "'" > _includes/igraph-cversions
	printf "$(RVERSIONS)" | tr -d "'" > _includes/igraph-rversions
	printf "$(PYVERSIONS)" | tr -d "'" > _includes/igraph-pyversions

jekyll: core c r python
	bundle exec jekyll build

devserver: core c r python
	bundle exec jekyll serve

vendor/bundle:
	bundle config set --local path 'vendor/bundle'
	bundle install
