.SUFFIXES:

NAME=norl
VERSION=2.3.5
DESCRIPTION= one-liners node.js, helps to write one line stdin filter program by node.js Javascript like perl/ruby.+JSON/CSV/Promise/Async/MultiStream feature(CLI tool/module)
KEYWORDS=one-liner oneliner perl ruby sed awk shell CLI command-line one line stdin JSON CSV async async.js Promise filter command join multiple sort

PKGKEYWORDS=$(shell echo $$(echo $(KEYWORDS)|perl -ape '$$_=join("\",\"",@F)'))

#=

COMMANDS=help pack test clean build

#=

DESTDIR=dist
COFFEES=$(wildcard *.coffee)
TARGETNAMES=$(patsubst %.coffee,%.js,$(COFFEES)) 
TARGETS=$(patsubst %,$(DESTDIR)/%,$(TARGETNAMES))
DOCNAMES=package.json LICENSE README.md
DOCS=$(patsubst %,$(DESTDIR)/%,$(DOCNAMES))
ALL=$(TARGETS) $(DOCS)
SDK=node_modules/.gitignore
TOOLS=node_modules/.bin

#=

.PHONY:$(COMMANDS)

default:build

build:$(TARGETS)

pack:$(ALL) test.passed|$(DESTDIR)

test:test.passed

clean:
	-rm -r $(DESTDIR) node_modules *.passed 2>/dev/null;true

help:
	@echo "Targets:$(COMMANDS)"

#=

test.passed:$(TARGETS) test.bats
	./test.bats
	touch $@

$(DESTDIR):
	mkdir -p $@

$(DESTDIR)/%.js:%.coffee |$(SDK) $(DESTDIR)
ifndef NC
	$(TOOLS)/coffee-jshint -o node $< 
endif
	head -n1 $<|grep '^#!'|sed 's/coffee/node/'  >$@ 
	cat $<|$(TOOLS)/coffee -bcs >> $@
	chmod +x $@

$(DESTDIR)/%:% $(TARGETS) Makefile|$(SDK) $(DESTDIR)
	cat $<|$(TOOLS)/partpipe -c VERSION=$(VERSION) NAME=$(NAME) "DESCRIPTION=$(DESCRIPTION)" 'KEYWORDS=$(PKGKEYWORDS)'  >$@

$(SDK):package.json
	npm install
	@touch $@
