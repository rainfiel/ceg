LIBNAME = ltest
LUADIR = /usr/local/include

COPT = -O2
# COPT = -DLPEG_DEBUG -g

CWARNS = -Wall -Wextra -pedantic \
	-Waggregate-return \
	-Wcast-align \
	-Wcast-qual \
	-Wdisabled-optimization \
	-Wpointer-arith \
	-Wshadow \
	-Wsign-compare \
	-Wundef \
	-Wwrite-strings \
	-Wbad-function-cast \
	-Wdeclaration-after-statement \
	-Wmissing-prototypes \
	-Wnested-externs \
	-Wstrict-prototypes \
# -Wunreachable-code \

CFLAGS = $(CWARNS) $(COPT) -std=c99 -I$(LUADIR) -fPIC
CC = gcc

FILES = ltest.o lpeg.o

# For Linux
linux:
	make ltest.so "DLLFLAGS = -shared -fPIC"
	make lpeg.so "DLLFLAGS = -shared -fPIC"

# For Mac OS
macosx:
	make ltest.so "DLLFLAGS = -bundle -undefined dynamic_lookup" & make lpeg.so "DLLFLAGS = -bundle -undefined dynamic_lookup"

ltest.so: ltest.o
	env $(CC) $(DLLFLAGS) ltest.o -o ltest.so

lpeg.so: lpeg.o
	env $(CC) $(DLLFLAGS) lpeg.o -o lpeg.so

$(FILES): Makefile

clean:
	rm -f $(FILES) ltest.so lpeg.so

ltest.o: ltest.c
lpeg.o: lpeg.c
