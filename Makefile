
all: core

.PHONY: all core c r python

CVERSION?=0.9.4
RVERSION?=1.2.6
PYVERSION?=0.9.1

# optional variable so we can update the C docs without making a release
# CCOMMITHASH?=8bca587ad
# optional variable so we can update the Python docs without making a release
# PYCOMMITHASH?=a92409f

CREPO=https://github.com/igraph/igraph
RREPO=https://github.com/igraph/rigraph
PYREPO=https://github.com/igraph/python-igraph

######################################################################
## C stuff

C=_build/c

c: core c/doc/stamp c/doc/igraph-docs.pdf

c/doc/stamp: $(C)/build/doc/jekyll/stamp
	rm -rf c/doc
	mkdir -p c
	cp -r $(C)/build/doc/jekyll c/doc

c/doc/igraph-docs.pdf: $(C)/build/doc/igraph-docs.pdf c/doc/stamp
	cp $(C)/build/doc/igraph-docs.pdf c/doc/

$(C)/build/doc/jekyll/stamp: $(C)/build/doc/html/stamp
	python3 _tools/jekyllify-c-docs.py $(C)/build && touch $(C)/build/doc/jekyll/stamp

$(C)/build/doc/html/stamp: $(C)/build/CMakeCache.txt
	cd $(C)/build && make html

$(C)/build/CMakeCache.txt: $(C)/stamp
	cd $(C) && mkdir build && cd build && cmake .. 

$(C)/stamp:
	rm -rf $(C)
	mkdir -p $(C)
	cd $(C) && ( \
		if [ "x$(CCOMMITHASH)" != x ]; then \
			git clone $(CREPO) . && git reset --hard $(CCOMMITHASH); \
		else \
			git clone --branch $(CVERSION) --depth 1 $(CREPO) .; \
		fi \
	)
	touch $@

$(C)/build/doc/igraph-docs.pdf: $(C)/doc/igraph-docs.xml c/doc/stamp
	cd $(C)/build && make pdf

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

ARCHFLAGS=-Wno-error=unused-command-line-argument

PY=_build/python

python: core python/doc/api/stamp python/doc/tutorial/stamp

python/doc/api/stamp: $(PY)/doc/api/html/index.html
	rm -rf python/doc/api
	mkdir -p python/doc/api
	cp -r $(PY)/doc/api/html/ python/doc/api
	_tools/pyhtml.sh python/doc/api
	touch $@

$(PY)/doc/api/html/index.html: $(PY)/stamp
	cd $(PY) && rm -rf vendor/build/igraph vendor/install/igraph
	cd $(PY) && if [ ! -d .venv ]; then python3 -m venv .venv; .venv/bin/pip install -U pydoctor wheel; fi
	export ARCHFLAGS=$(ARCHFLAGS) && cd $(PY) && .venv/bin/python setup.py build
	cd $(PY) && .venv/bin/python setup.py install && scripts/mkdoc.sh

python/doc/tutorial/stamp: $(PY)/stamp
	mkdir -p python/doc/tutorial
	cd $(PY)/doc && ../.venv/bin/python -m sphinx.cmd.build source tutorial
	cp -r $(PY)/doc/tutorial/ python/doc/tutorial/
	touch $@

$(PY)/stamp:
	rm -rf $(PY)
	mkdir -p $(PY)
	cd $(PY) && ( \
		if [ "x$(PYCOMMITHASH)" != x ]; then \
			git clone $(PYREPO) . && git reset --hard $(PYCOMMITHASH); \
		else \
			git clone --branch $(PYVERSION) --depth 1 $(PYREPO) .; \
		fi \
	) && git submodule update --init
	cd $(PY) && if [ ! -d .venv ]; then python3 -m venv .venv; fi
	cd $(PY) && .venv/bin/pip install pydoctor Sphinx sphinxbootstrap4theme
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
	bundle exec jekyll build
	touch stamp
