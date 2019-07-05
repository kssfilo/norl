.SUFFIXES:

NAME=norl
VERSION=0.0.1
DESCRIPTION=One Liner NODE.js, Helps to write one line node.js stdin filter program like perl or ruby.(CLI tool/module)
KEYWORDS=one-liner oneliner perl ruby shell CLI command-line

PKGKEYWORDS=$(shell echo $$(echo $(KEYWORDS)|perl -ape '$$_=join("\",\"",@F)'))

#=

COMMANDS=help pack test clean

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

default:help

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
