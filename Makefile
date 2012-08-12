PROLOG    = swipl -O
PROLOG_LD = swipl-ld
CC        = gcc
FLAGS     = -shared -fPIC -O4 -Wall -Wextra -cc-options,-ansi,-pedantic

.PHONY: all
all: compile test

.PHONY: test
test: compile
	@ echo "--- Run tests and exit ..."
	time $(PROLOG) -s load -g test -t halt

.PHONY: cov
cov: compile
	@ echo "--- Run tests, print test coverage and exit ..."
	$(PROLOG) -s load -g cov -t halt

.PHONY: repl
repl: compile
	@ echo "--- Load and enter REPL ..."
	$(PROLOG) -s load -g repl

.PHONY: compile
compile: setup lib/bson_bits

# Generic name (not sure what file extensions different systems use).
lib/bson_bits: ext/bson_bits.c Makefile
	@ echo "--- Compile foreign library 'bson_bits' ..."
	rm -f $@
	$(PROLOG_LD) -o $@.dylib ext/bson_bits.c $(FLAGS) -cc $(CC)
	mv $@.dylib $@

.PHONY: setup
setup: lib

lib:
	mkdir -p lib

.PHONY: clean
clean:
	rm -rf lib/*
