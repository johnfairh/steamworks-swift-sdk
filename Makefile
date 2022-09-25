#
# `make install` to install to /usr/local
# `make uninstall` to try and uninstall from /usr/local
#
# `PREFIX=/opt make install` to install to /opt
#

STEAM_SDK_VERSION := 1.54

PREFIX ?= /usr/local

.PHONY: all install uninstall redist

all:
	@echo This Makefile installs or uninstalls Steamworks SDK files in a very
	@echo unofficial way so you can use the steamworks-swift project module to
	@echo write Steamworks API calls in Swift.  Use 'make install' if that really
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

# No libs stuff in the pkgconfig because we expect to be used
# with modulemaps and there are multiple possible libraries.

define PKGCONFIG
Name: ${PKG_NAME}
Description: Steamworks API wrapper for Swift language
URL: https://github.com/johnfairh/steamworks-swift
Version: ${STEAM_SDK_VERSION}
Cflags: -I${INST_H_DIR}
endef
export PKGCONFIG

PKGCONFIG_FILE := ${PREFIX}/lib/pkgconfig/${PKG_NAME}.pc

install:
	install -d ${INST_LIB_DIR} ${INST_H_DIR}
	for LIB in $(notdir $(wildcard ${LOCAL_LIB_DIR}/*)) ; do \
		install -vC ${LOCAL_LIB_DIR}/$${LIB} ${INST_LIB_DIR}; \
		ln -sf ${INST_LIB_DIR}/$${LIB} ${PREFIX}/lib/$${LIB}; \
	done
	cp -fR ${LOCAL_INCLUDE_DIR}/* ${INST_H_DIR}
	echo "$${PKGCONFIG}" > ${PKGCONFIG_FILE}

# Uninstall the SDK artifacts and pkg-config

uninstall:
	@for LIB in $(notdir $(wildcard ${INST_LIB_DIR}/*)) ; do \
		rm -f ${PREFIX}/lib/$${LIB}; \
	done
	rm -rf ${INST_LIB_DIR}
	rm -rf ${INST_H_DIR}
	rm -f ${PKGCONFIG_FILE}

# Populate the 'redist' tree from a Steamworks SDK - this is for
# maintaining the 

STEAM_SDK ?= ${CURDIR}/sdk

REDIST_ARCHS := osx win64 linux64

redist:
	rm -rf redist/*
	mkdir -p redist/include/steam redist/lib
	cp ${STEAM_SDK}/public/steam/*h redist/include/steam
	cp ${STEAM_SDK}/public/steam/*json redist/include/steam
	cp ${STEAM_SDK}/Readme.txt redist/
	for ARCH in ${REDIST_ARCHS} ; do \
		mkdir -p redist/lib/$${ARCH} ; \
		cp ${STEAM_SDK}/redistributable_bin/$${ARCH}/* redist/lib/$${ARCH}; \
		cp ${STEAM_SDK}/public/steam/lib/$${ARCH}/* redist/lib/$${ARCH}; \
	done
	@echo Now go update STEAM_SDK_VERSION in Makefile.