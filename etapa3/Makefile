# Makefile — Etapa 3 (TAC Completo) — INF01083 — 2026/2
TARGET  = lara
SRCDIR  = src
CC      = gcc
CFLAGS  = -Wall -Wextra -g -std=c11 -D_POSIX_C_SOURCE=200809L -D_DEFAULT_SOURCE -I$(SRCDIR)
FLEX    = flex
BISON   = bison

BISON_OUT = $(SRCDIR)/parser.tab.c
BISON_H   = $(SRCDIR)/parser.tab.h
FLEX_OUT  = $(SRCDIR)/lex.yy.c

C_SRCS = $(SRCDIR)/ast.c $(SRCDIR)/symtab.c $(SRCDIR)/ast_walk.c \
         $(SRCDIR)/tac.c $(SRCDIR)/codegen.c $(SRCDIR)/backpatch.c \
         $(SRCDIR)/main.c
ALL_SRCS = $(BISON_OUT) $(FLEX_OUT) $(C_SRCS)
OBJS = $(ALL_SRCS:.c=.o)

.PHONY: all clean test tests

all: $(TARGET) compilador

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

compilador: $(TARGET)
	ln -sf $(TARGET) compilador

$(BISON_OUT) $(BISON_H): $(SRCDIR)/parser.y
	$(BISON) -d -o $(BISON_OUT) $(SRCDIR)/parser.y

$(FLEX_OUT): $(SRCDIR)/scanner.l $(BISON_H)
	env -i PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin" HOME="$${HOME}" TMPDIR="$${TMPDIR}" LANG="C" \
	    $(FLEX) -o $(FLEX_OUT) $(SRCDIR)/scanner.l

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(SRCDIR)/lex.yy.c $(SRCDIR)/parser.tab.c $(SRCDIR)/parser.tab.h
	rm -f $(SRCDIR)/*.o $(TARGET) compilador etapa3
	rm -f _test.s _test_bin /tmp/_test_e3.s /tmp/_test_e3_bin /tmp/_actual_e3_*.txt /tmp/_expected_e3_*.txt

test: $(TARGET)
	@bash tests/run_tests.sh

tests: test
