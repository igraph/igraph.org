
all: core c r python

.PHONY: all core c r python

CVERSION?=0.7.1
RVERSION?=0.7.1
PYVERSION?=0.7.0

REPO=https://github.com/igraph/igraph
TMP:=$(shell mktemp -d /tmp/.XXXXX)

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
	cd $(C) && git clone --branch $(CVERSION) --depth 1 $(REPO) .
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
	cd $(R)/interfaces/R && make && \
	R CMD INSTALL --html --no-R --no-configure --no-inst \
	  --no-libs --no-exec --no-test-load -l $(TMP) igraph
	rm -rf r/doc
	mkdir -p r/doc
	$(R)/tools/rhtml.sh $(TMP)/igraph/html r/doc
	ln -s 00Index.html r/doc/index.html
	touch r/doc/stamp

r/doc/igraph.pdf: r/doc/stamp
	mkdir -p r/doc
	cd $(R)/interfaces/R/ && make
	R CMD Rd2pdf --no-preview --force -o r/doc/igraph.pdf \
	  $(R)/interfaces/R/igraph

$(R)/stamp:
	rm -rf $(R)
	mkdir -p $(R)
	cd $(R) && git clone --branch $(RVERSION) --depth 1 $(REPO) .
	touch $@

######################################################################
## Python stuff

ARCHFLAGS=-Wno-error=unused-command-line-argument-hard-error-in-future

PY=_build/python

python: core python/doc/python-igraph.pdf python/doc/stamp \
	python/doc/tutorial/stamp

python/doc/python-igraph.pdf: $(PY)/interfaces/python/doc/api/pdf/api.pdf
	mkdir -p python/doc
	cp $< $@

python/doc/stamp: $(PY)/stamp
	mkdir -p python/doc
	cp -r $(PY)/interfaces/python/doc/api/html/ python/doc
	$(PY)/tools/pyhtml.sh python/doc
	touch $@

$(PY)/interfaces/python/doc/api/pdf/api.pdf: $(PY)/stamp
	cd $(PY) && ./bootstrap.sh && ./configure && make dist
	export ARCHFLAGS=$(ARCHFLAGS) && cd $(PY)/interfaces/python && \
		python setup.py build \
			--no-pkg-config --no-progress-bar	\
			--c-core-url=../../igraph-$(PYVERSION).tar.gz
	cd $(PY)/interfaces/python && scripts/mkdoc.sh

python/doc/tutorial/stamp: $(PY)/stamp
	mkdir -p python/doc/tutorial
	cd $(PY)/interfaces/python/doc && sphinx-build source api/tutorial
	cp -r $(PY)/interfaces/python/doc/api/tutorial/ python/doc/tutorial/
	touch $@

$(PY)/stamp:
	rm -rf $(PY)
	mkdir -p $(PY)
	cd $(PY) && git clone --branch $(PYVERSION) --depth 1 $(REPO) .
	touch $@

######################################################################
## Core stuff

core: stamp

HTML= index.html _layouts/default.html _layouts/newstemp.html \
	_layouts/manual.html c/news.html c/index.html \
	r/news.html r/index.html python/news.html python/index.html

CSS= css/affix.css css/manual.css css/other.css fonts/fonts.css

POSTS= $(wildcard _posts/*)

stamp: $(HTML) $(CSS) $(POSTS)
	echo $(CVERSION) > _includes/igraph-cversion
	echo $(RVERSION) > _includes/igraph-rversion
	echo $(PYVERSION) > _includes/igraph-pyversion
	jekyll build
	touch stamp

######################################################################
## Deployment

deploy: core-deploy c-deploy r-deploy python-deploy

test: core-deploy-test c-deploy-test r-deploy-test python-deploy-test

core-deploy:
	rsync -avz --delete --exclude /python --exclude /r --exclude /c \
		_site/* igraph.org:www/

c-deploy:
	rsync -avz --delete _site/c igraph.org:www/

r-deploy:
	rsync -avz --delete _site/r igraph.org:www/

python-deploy:
	rsync -avz --delete _site/python igraph.org:www/

core-deploy-test:
	rsync -avz --delete --exclude /python --exclude /r --exclude /c \
		_site/* igraph.org:www2/www-test/

c-deploy-test:
	rsync -avz --delete _site/c igraph.org:www2/www-test/

r-deploy-test:
	rsync -avz --delete _site/r igraph.org:www2/www-test/

python-deploy-test:
	rsync -avz --delete _site/python igraph.org:www2/www-test/

.PHONY: deploy core-deploy c-deploy r-deploy python-deploy \
	test core-deploy-test c-deploy-test r-deploy-test python-deploy-test
