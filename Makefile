.SUFFIXES:

NAME=norl
VERSION=1.1.0
DESCRIPTION=one liners node.js, helps to write one line stdin filter program by node.js Javascript like perl/ruby.+JSON/CSV/Promise feature(CLI tool/module)
KEYWORDS=one-liner oneliner perl ruby shell CLI command-line one line stdin JSON CSV

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

pack:$(ALL)|$(DESTDIR)

test:$(TARGETS) test.bats
	./test.bats

clean:
	-rm -r $(DESTDIR) node_modules

help:
	@echo "Targets:$(COMMANDS)"

#=

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
	cat $<|$(TOOLS)/partpipe -c VERSION@$(VERSION) NAME@$(NAME) "DESCRIPTION@$(DESCRIPTION)" 'KEYWORDS@$(PKGKEYWORDS)'  >$@

$(SDK):package.json
	npm install
	@touch $@
