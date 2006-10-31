#!make
OBJECTS=main.o zlib.o hash_tables.o grf.o
TARGET=libgrf.so
TARGET_WIN=grf.dll
BUILD=unknown
LDFLAGS=--shared
LDFLAGS_TEST=
INCLUDES=-Iincludes -Izlib
ifndef DEBUG
DEBUG=yes
endif
ifeq ($(DEBUG),no)
CFLAGS=-O3 -Wall --std=gnu99
else
CFLAGS=-g -ggdb -O0 -Wall --std=gnu99 -D__DEBUG
endif

ZOBJS = adler32.o compress.o crc32.o gzio.o uncompr.o deflate.o trees.o \
        zutil.o inflate.o infback.o inftrees.o inffast.o

UNAME=$(shell uname -s  | sed -e 's/_.*$$//')
ifeq ($(UNAME),Linux)
# *****
# *** Linux config
# *****
CC=gcc32
# /opt/xmingw/ for gentoo, i586-mingw32msvc-gcc for debian
ifeq ($(shell which i586-mingw32msvc-gcc 2>/dev/null),)
CC_WIN=/opt/xmingw/bin/i386-mingw32msvc-gcc
else
CC_WIN=i586-mingw32msvc-gcc
endif
BUILD=Linux
WINFLAGS=-D__WIN32
LINFLAGS=-fPIC -DPIC

else
ifeq ($(UNAME),CYGWIN)
# *****
# *** Cygwin config
# *****
CC=gcc
CC_WIN=gcc
BUILD=Cygwin
WINFLAGS=-mno-cygwin -mwindows -D__WIN32
LINFLAGS=

endif
endif

win32/%.o: %.c
	@echo -en "  CC\t$<           \015"
	@$(CC_WIN) $(CFLAGS) $(WINFLAGS) $(INCLUDES) -c -o $@ $<

linux/%.o: %.c
	@echo -en "  CC\t$<           \015"
	@$(CC) $(CFLAGS) $(LINFLAGS) $(INCLUDES) -c -o $@ $<

win32/%.o: zlib/%.c
	@echo -en "  CC\t$<           \015"
	@$(CC_WIN) $(CFLAGS) $(WINFLAGS) $(INCLUDES) -c -o $@ $<

linux/%.o: zlib/%.c
	@echo -en "  CC\t$<           \015"
	@$(CC) $(CFLAGS) $(LINFLAGS) $(INCLUDES) -c -o $@ $<

.PHONY: make_dirs test

ifeq ($(BUILD),unknown)
all: ;@echo "Unknown system $(UNAME) !"
else
all: make_dirs $(TARGET) grf_test_linux $(TARGET_WIN) grf_test_win.exe
endif

make_dirs:
	@mkdir win32 linux 2>/dev/null || true

$(TARGET_WIN): $(patsubst %.o,win32/%.o,$(ZOBJS) $(OBJECTS))
	@echo -e "  LD\t$@              "
	@$(CC_WIN) $(CFLAGS) $(WINFLAGS) $(LDFLAGS) -o $@ $^

$(TARGET): $(patsubst %.o,linux/%.o,$(ZOBJS) $(OBJECTS))
	@echo -e "  LD\t$@              "
	@$(CC) $(CFLAGS) $(LINFLAGS) $(LDFLAGS) -o $@ $^

grf_test_win.exe: win32/test.o $(TARGET_WIN)
	@echo -e "  LD\t$@              "
	@$(CC_WIN) $(CFLAGS) $(WINFLAGS) $(LDFLAGS_TEST) -o $@ $< -L. -lgrf

grf_test_linux: linux/test.o $(TARGET)
	@echo -e "  LD\t$@              "
	@$(CC) $(CFLAGS) $(LINFLAGS) $(LDFLAGS_TEST) -o $@ $< -L. -lgrf

ifeq ($(UNAME),Linux)
test: make_dirs grf_test_linux
	@LD_LIBRARY_PATH="." ./grf_test_linux

gdb: make_dirs grf_test_linux
	@LD_LIBRARY_PATH="." gdb ./grf_test_linux
else
ifeq ($(UNAME),CYGWIN)
test: make_dirs grf_test_win.exe
	./grf_test_win.exe
else
test: ;@echo "No test available for your platform ($(UNAME))."
endif
endif

clean:
	rm -fr linux $(TARGET) win32 $(TARGET_WIN) grf_test_win.exe grf_test_linux
