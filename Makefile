
all: core

.PHONY: all core c r python

CVERSION?=0.8.0
RVERSION?=1.2.4.1
PYVERSION?=master

CREPO=https://github.com/igraph/igraph
RREPO=https://github.com/igraph/rigraph
PYREPO=https://github.com/igraph/python-igraph

######################################################################
## C stuff

C=_build/c

c: core c/doc/stamp c/doc/igraph.info c/doc/igraph-docs.pdf

c/doc/stamp: $(C)/doc/jekyll/stamp
	rm -rf c/doc
	mkdir -p c
	cp -r $(C)/doc/jekyll c/doc

c/doc/igraph-docs.pdf: $(C)/doc/igraph-docs.pdf c/doc/stamp
	cp $(C)/doc/igraph-docs.pdf c/doc/

c/doc/igraph.info: $(C)/doc/igraph.info c/doc/stamp
	cp $(C)/doc/igraph.info c/doc/

$(C)/doc/jekyll/stamp:  $(C)/doc/html/stamp
	cd $(C)/doc && make jekyll

$(C)/doc/html/stamp: $(C)/doc/Makefile
	cd $(C)/doc && make html

$(C)/doc/Makefile: $(C)/stamp
	cd $(C) && ./bootstrap.sh
	cd $(C) && ./configure

$(C)/stamp:
	rm -rf $(C)
	mkdir -p $(C)
	cd $(C) && git clone --branch $(CVERSION) --depth 1 $(CREPO) .
	touch $@

$(C)/doc/igraph-docs.pdf: $(C)/doc/igraph-docs.xml c/doc/stamp
	cd $(C)/doc && make igraph-docs.pdf

$(C)/doc/igraph.info: $(C)/doc/igraph-docs.xml c/doc/stamp
	cd $(C)/doc && make igraph.info

######################################################################
## R stuff

R=_build/r

r: core r/doc/stamp r/doc/igraph.pdf

r/doc/stamp: $(R)/stamp
	$(eval TMP := $(shell mktemp -d /tmp/.XXXXX))
	cd ${R} && \
	R CMD INSTALL --html --no-R --no-configure --no-inst \
	  --no-libs --no-exec --no-test-load -l $(TMP) .
	rm -rf r/doc
	mkdir -p r/doc
	_tools/rhtml.sh $(TMP)/igraph/html r/doc
	ln -s 00Index.html r/doc/index.html
	touch r/doc/stamp
	rm -rf $(TMP)

r/doc/igraph.pdf: r/doc/stamp
	mkdir -p r/doc
	R CMD Rd2pdf --no-preview --force -o r/doc/igraph.pdf $(R)

$(R)/stamp:
	rm -rf $(R)
	mkdir -p $(R)
	cd $(R) && \
		curl -s https://cran.r-project.org/src/contrib/igraph_$(RVERSION).tar.gz \
		| tar --strip-components 1 -xzf -
	touch $@

######################################################################
## Python stuff

# TODO(ntamas): switch to doing everything in a virtualenv once we switched
# from Epydoc to Sphinx so we can build stuff in Python 3

ARCHFLAGS=-Wno-error=unused-command-line-argument

PY=_build/python

python: core python/doc/python-igraph.pdf python/doc/stamp \
	python/doc/tutorial/stamp

python/doc/python-igraph.pdf: $(PY)/doc/api/pdf/api.pdf
	mkdir -p python/doc
	cp $< $@

python/doc/stamp: $(PY)/doc/api/html/index.html
	mkdir -p python/doc
	cp -r $(PY)/doc/api/html/ python/doc
	_tools/pyhtml.sh python/doc
	touch $@

$(PY)/doc/api/html/index.html $(PY)/doc/api/pdf/api.pdf: $(PY)/stamp
	cd $(PY) && rm -f igraphcore
	export ARCHFLAGS=$(ARCHFLAGS) && cd $(PY) && python setup.py build
	cd $(PY) && scripts/mkdoc.sh

python/doc/tutorial/stamp: $(PY)/stamp
	mkdir -p python/doc/tutorial
	cd $(PY)/doc && python -m sphinx.cmd.build source tutorial
	cp -r $(PY)/doc/tutorial/ python/doc/tutorial/
	touch $@

$(PY)/stamp:
	rm -rf $(PY)
	mkdir -p $(PY)
	cd $(PY) && git clone --branch $(PYVERSION) --depth 1 $(PYREPO) . && \
	    git submodule update --init
	cd $(PY) && pip install --user epydoc Sphinx sphinx_bootstrap_theme
	touch $@

######################################################################
## Core stuff

core: stamp

HTML= index.html news.html _layouts/default.html \
	_layouts/manual.html c/index.html c/compilation-windows.html \
	r/index.html python/index.html

CSS= css/affix.css css/manual.css css/other.css fonts/fonts.css

POSTS= $(wildcard _posts/*)

stamp: $(HTML) $(CSS) $(POSTS)
	echo $(CVERSION) > _includes/igraph-cversion
	echo $(RVERSION) > _includes/igraph-rversion
	echo $(PYVERSION) > _includes/igraph-pyversion
	jekyll build
	touch stamp
