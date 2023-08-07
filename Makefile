#
# `make install` to install to /usr/local
# `make uninstall` to try and uninstall from /usr/local
#
# `PREFIX=/opt make install` to install to /opt
#

STEAM_SDK_VERSION := 1.57

PREFIX ?= /usr/local

.PHONY: all install uninstall redist

all:
	@echo This Makefile installs or uninstalls Steamworks SDK files in a very
	@echo unofficial way so you can use the steamworks-swift project module to
	@echo write Steamworks API calls in Swift.  Use \'make install\' if that really
	@echo is what you want to do.

# Only tested on macOS but show willing.  Good chance Linux will be OK.

ifeq (${OS},Windows_NT)
  PLATFORM := win64
else
  ifeq ($(shell uname -s),Darwin)
    PLATFORM := osx
  else
    PLATFORM := linux64
  endif
endif

LOCAL_LIB_DIR := ${CURDIR}/redist/lib/${PLATFORM}
LOCAL_INCLUDE_DIR := ${CURDIR}/redist/include

# Install Steamworks SDK artifacts into the system

# Use a subdirectory for headers & libs to find them for uninstall
# and to try and avoid any clashes.

PKG_NAME := steamworks-swift

INST_LIB_DIR := ${PREFIX}/lib/${PKG_NAME}
INST_H_DIR := ${PREFIX}/include/${PKG_NAME}

# No library names in the pkgconfig because we expect to be used
# with modulemaps and there are multiple possible libraries.
# (the -L is required because, even though the libraries are in
# /usr/lib, Swift ignores that by default and looks in the toolchain
# version of /usr/lib only...)

define PKGCONFIG
Name: ${PKG_NAME}
Description: Steamworks API wrapper for Swift language
URL: https://github.com/johnfairh/steamworks-swift-sdk
Version: ${STEAM_SDK_VERSION}
Cflags: -I${INST_H_DIR}
Libs: -L${INST_LIB_DIR}
endef
export PKGCONFIG

PKGCONFIG_DIR := ${PREFIX}/lib/pkgconfig
PKGCONFIG_FILE := ${PKGCONFIG_DIR}/${PKG_NAME}.pc

# Intentionally break the codesign to make development life easier -
# another workaround for the lack of binary targets.

install:
	mkdir -p ${INST_LIB_DIR} ${INST_H_DIR} ${PKGCONFIG_DIR}
	for LIB in $(notdir $(wildcard ${LOCAL_LIB_DIR}/*)) ; do \
		install -vC ${LOCAL_LIB_DIR}/$${LIB} ${INST_LIB_DIR}; \
		ln -sf ${INST_LIB_DIR}/$${LIB} ${PREFIX}/lib/$${LIB}; \
	done
ifeq (${PLATFORM},osx)
	for LIB in $(notdir $(wildcard ${LOCAL_LIB_DIR}/*)) ; do \
		install_name_tool -id ${INST_LIB_DIR}/$${LIB} ${PREFIX}/lib/$${LIB} 2>/dev/null; \
	done
endif
ifeq (${PLATFORM},linux64)
	ldconfig # we love you ldd
endif
	cp -fR ${LOCAL_INCLUDE_DIR}/* ${INST_H_DIR}
	echo "$${PKGCONFIG}" > ${PKGCONFIG_FILE}

# Uninstall the SDK artifacts and pkg-config

uninstall:
	for LIB in $(notdir $(wildcard ${INST_LIB_DIR}/*)) ; do \
		rm -f ${PREFIX}/lib/$${LIB}; \
	done
	rm -rf ${INST_LIB_DIR}
	rm -rf ${INST_H_DIR}
	rm -f ${PKGCONFIG_FILE}

# Populate the 'redist' tree from a Steamworks SDK - this is for
# maintaining this redistribution.

STEAM_SDK ?= ${CURDIR}/sdk

REDIST_ARCHS := osx win64 linux64

# Filter out some headers
ALL_HEADERS := $(notdir $(wildcard ${STEAM_SDK}/public/steam/*h))
BAD_HEADERS := isteamdualsense.h
GOOD_HEADERS := $(filter-out ${BAD_HEADERS},${ALL_HEADERS})

redist:
	rm -rf redist/*
	mkdir -p redist/include/steam redist/lib
	cp $(addprefix ${STEAM_SDK}/public/steam/,${GOOD_HEADERS}) redist/include/steam
	cp ${STEAM_SDK}/public/steam/*json redist/include/steam
	cp ${STEAM_SDK}/Readme.txt redist/
	for ARCH in ${REDIST_ARCHS} ; do \
		mkdir -p redist/lib/$${ARCH} ; \
		cp ${STEAM_SDK}/redistributable_bin/$${ARCH}/* redist/lib/$${ARCH}; \
		cp ${STEAM_SDK}/public/steam/lib/$${ARCH}/* redist/lib/$${ARCH}; \
	done
	@echo Now go update STEAM_SDK_VERSION in Makefile.
