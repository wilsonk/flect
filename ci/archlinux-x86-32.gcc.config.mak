# This is a configuration for ci.lycus.org test runs.

export FLECT_ARCH       ?= x86
export FLECT_OS         ?= linux
export FLECT_ABI        ?= x86-sysv32
export FLECT_CROSS      ?= false

export FLECT_CC         ?= gcc
export FLECT_CC_TYPE    ?= gcc
export FLECT_CC_ARGS    ?= -m32
export FLECT_LD         ?= ld
export FLECT_LD_TYPE    ?= ld
export FLECT_LD_ARGS    ?=

export FLECT_PREFIX     ?= /usr/local
export FLECT_BIN_DIR    ?= /usr/local/bin
export FLECT_LIB_DIR    ?= /usr/local/lib
export FLECT_ST_LIB_DIR ?= /usr/local/lib/static
export FLECT_SH_LIB_DIR ?= /usr/local/lib/shared
