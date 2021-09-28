
all: core

.PHONY: all core c r python devserver

# Default doc version
CVERSION?=0.9.4
RVERSION?=1.2.6
PYVERSION?=0.9.6

# Available versions
CVERSIONS?='0.8.1 0.9.0 0.9.4 master develop'
RVERSIONS?='1.2.3 1.2.4 1.2.5 1.2.6'
PYVERSIONS?='0.9.0 0.9.6 master develop'
PYCVERSIONS?='0.9.0 0.9.4 0.9.4 develop'

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
	rm -rf c/doc
	rm -rf $(C)

c: core c/doc/stamp c/doc/igraph-docs.pdf

c/doc/stamp: $(C)/build/doc/jekyll/stamp
	rm -rf c/doc
	mkdir -p c/doc
	cp -r $(C)/build/doc/jekyll c/doc/
	cp -r $(C)/build/doc/pdf c/doc/

c/doc/igraph-docs.pdf: $(C)/build/doc/stamp
	cp $(C)/build/doc/pdf/$(CVERSION)/igraph-docs.pdf c/doc/

$(C)/build/doc/jekyll/stamp: $(C)/build/doc/stamp
	python3 _tools/jekyllify-c-docs.py $(C)/build $(CVERSIONS) && touch $(C)/build/doc/jekyll/stamp

$(C)/build/doc/stamp: $(C)/stamp
	_tools/c_build_versioned.sh $(C) $(CVERSIONS)
	touch $@

$(C)/stamp:
	mkdir -p $(C)
	cd $(C) && git status || ( \
		if [ "x$(CCOMMITHASH)" != x ]; then \
			git clone $(CREPO) . && git reset --hard $(CCOMMITHASH); \
		else \
			git clone $(CREPO) .; \
		fi \
	)
	touch $@

######################################################################
## R stuff

R=_build/r


clean_r:
	rm -rf r/doc
	rm -rf $(R)

r: core r/doc/stamp r/doc/igraph.pdf

r/doc/stamp: $(R)/stamp
	mkdir -p r/doc
	cp -r $(R)/build/doc/html r/doc/
	cp -r $(R)/build/doc/pdf r/doc/
	mkdir -p r/doc/jekyll
	_tools/rhtml.sh r/doc/html r/doc/jekyll
	ln -s r/doc/html/$(RVERSION)/00Index.html r/doc/index.html
	touch r/doc/stamp
	rm -rf $(TMP)

r/doc/igraph.pdf: r/doc/stamp
	cp r/doc/pdf/$(RVERSION)/igraph.pdf r/doc/

$(R)/stamp:
	mkdir -p $(R)
	_tools/r_build_versioned.sh $(R) $(RVERSIONS) $(RVERSION)
	touch $@

######################################################################
## Python stuff

ARCHFLAGS=-Wno-error=unused-command-line-argument

PY=_build/python

clean_python:
	rm -rf python/doc/api
	rm -rf python/doc/tutorial
	rm -rf $(PY)

python: core python/doc/api/stamp python/doc/tutorial/stamp

python/doc/api/stamp: $(PY)/doc/api/stamp
	rm -rf python/doc/api
	mkdir -p python/doc/api
	cp -r $(PY)/doc/api_versions/* python/doc/api/
	_tools/pyhtml.sh python/doc/api
	touch $@

$(PY)/doc/api/stamp: $(PY)/stamp
	export ARCHFLAGS=$(ARCHFLAGS) && _tools/py_build_versioned_api.sh $(PY) $(PYVERSIONS) $(PYCVERSIONS)
	touch $@

python/doc/tutorial/stamp: $(PY)/doc/tutorial/stamp
	rm -rf python/doc/tutorial
	mkdir -p python/doc/tutorial
	cp -r $(PY)/doc/tutorial_versions/* python/doc/tutorial/
	touch $@

$(PY)/doc/tutorial/stamp: $(PY)/stamp
	_tools/py_build_versioned_tutorial.sh $(PY) $(PYVERSIONS)
	touch $@

$(PY)/stamp:
	mkdir -p $(PY)
	cd $(PY) && git status || ( \
		if [ "x$(PYCOMMITHASH)" != x ]; then \
			git clone $(PYREPO) . && git reset --hard $(PYCOMMITHASH); \
		else \
			git clone $(PYREPO) .; \
		fi \
	) && git submodule update --init
	cd $(PY) && if [ ! -d .venv ]; then python3 -m venv .venv; fi
	cd $(PY) && .venv/bin/pip install epydoc pydoctor wheel Sphinx sphinxbootstrap4theme
	_tools/patch-pydoctor.sh $(PY) || true
	touch $@

######################################################################
## Core stuff

core: stamp

HTML= index.html news.html code-of-conduct.html _layouts/default.html \
	_layouts/manual.html c/index.html r/index.html python/index.html

CSS= css/affix.css css/manual.css css/other.css fonts/fonts.css

POSTS= $(wildcard _posts/*)

stamp: $(HTML) $(CSS) $(POSTS)
	printf "$(CVERSION)" > _includes/igraph-cversion
	printf "$(RVERSION)" > _includes/igraph-rversion
	printf "$(PYVERSION)" > _includes/igraph-pyversion
	printf "$(CVERSIONS)" > _includes/igraph-cversions
	printf "$(RVERSIONS)" > _includes/igraph-rversions
	printf "$(PYVERSIONS)" > _includes/igraph-pyversions
	bundle exec jekyll build
	touch stamp

devserver: stamp
	bundle exec jekyll serve -d docs
	
