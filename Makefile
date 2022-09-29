
all: jekyll

.PHONY: all core c r python jekyll devserver

# Default doc version
CVERSION?=0.10.1
RVERSION?=1.3.5
PYVERSION?=0.10.1

# Available versions
CVERSIONS   ?= '0.9.0 0.9.4 0.9.5 0.9.6 0.9.7 0.9.8 0.9.9 0.9.10 0.10.0 0.10.1 master develop'
RVERSIONS   ?= '1.2.3 1.2.4 1.2.5 1.2.6 1.2.7 1.3.0 1.3.1 1.3.2 1.3.3 1.3.4 1.3.5'
PYVERSIONS  ?= '0.9.6 0.9.7 0.9.8 0.9.9 0.9.10 0.9.11 0.10.0 0.10.1 master develop'
PYCVERSIONS ?= '0.9.4 0.9.4 0.9.4 0.9.6  0.9.8  0.9.9 0.10.0 0.10.1 master develop'

# FIXME: this is broken now
# optional variable so we can update the C docs without making a release
# CCOMMITHASH?=8bca587ad
# optional variable so we can update the Python docs without making a release
# PYCOMMITHASH?=9bde4c29f

CREPO=https://github.com/igraph/igraph
RREPO=https://github.com/igraph/rigraph
PYREPO=https://github.com/igraph/python-igraph

######################################################################
## C stuff

C=_build/c

clean_c:
	rm -rf c/html c/pdf c/stamp
	rm -rf $(C)

update_c:
	rm -rf c/stamp $(C)/build/doc/stamp $(C)/stamp
	$(MAKE) c

c: core c/stamp

c/stamp: $(C)/build/doc/stamp
	mkdir -p c/pre
	python3 _tools/c_postprocess_html.py $(C)/build/doc/html c/html $(CVERSIONS) $(CVERSION)
	cp -r $(C)/build/doc/pdf c/
	touch $@

$(C)/build/doc/stamp: $(C)/stamp
	_tools/c_build_versioned.sh $(C) $(CVERSIONS)
	touch $@

$(C)/stamp:
	mkdir -p $(C)
	# Clone repo if not present, fetch updates if it is present
	if [ ! -d $(C)/.git ]; then \
		cd $(C) && \
		git clone $(CREPO) .; \
	else \
		cd $(C) && \
		git fetch; \
	fi
	touch $@

######################################################################
## R stuff

R=_build/r


clean_r:
	rm -rf r/pre r/html r/pdf
	rm -rf $(R)

update_r:
	rm -rf r/stamp $(R)/stamp
	$(MAKE) r

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

PY_ARCHFLAGS=-Wno-error=unused-command-line-argument -Wno-error=unused-but-set-variable

PY=_build/python

clean_python:
	rm -rf python/api
	rm -rf python/tutorial
	rm -rf $(PY)

update_python:
	rm -rf python/stamp $(PY)/stamp
	$(MAKE) python

python: core python/stamp

python/stamp: $(PY)/stamp
	export ARCHFLAGS="$(PY_ARCHFLAGS)" && _tools/py_build_versioned.sh $(PY) $(PYVERSIONS) $(PYCVERSIONS)
	_tools/py_postprocess_html.py $(PY) $(PYVERSIONS)
	touch $@

$(PY)/stamp:
	mkdir -p $(PY)
	# Clone repo if not present, fetch updates if it is present
	if [ ! -d $(PY)/.git ]; then \
		cd $(PY) && \
		git clone $(PYREPO) . && \
		git submodule update --init; \
	else \
		cd $(PY) && \
		git fetch; \
	fi
	# Make virtual environment if not present
	if [ ! -d $(PY)/.venv ]; then \
		cd $(PY) && \
		python3 -m venv .venv && \
		.venv/bin/pip install epydoc matplotlib pydoctor wheel Sphinx sphinxbootstrap4theme; \
	fi
	touch $@

######################################################################
## Core stuff

HTML= index.html news.html code-of-conduct.html \
      _layouts/default.html _layouts/r-manual.html _layouts/c-manual.html \
      c/index.html r/index.html

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
