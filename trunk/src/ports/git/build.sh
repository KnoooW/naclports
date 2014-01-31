#!/bin/bash
# Copyright (c) 2013 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Do a verbose build so we're confident it's hitting nacl's tools.
MAKE_TARGETS="V=1"
EXTRA_CONFIGURE_ARGS="--prefix= --exec-prefix="
BUILD_DIR=${SRC_DIR}
NACL_CONFIGURE_PATH=./configure

ConfigureStep() {
  ChangeDir ${SRC_DIR}
  autoconf

  if [[ "${NACL_GLIBC}" != 1 ]]; then
    readonly GLIBC_COMPAT=${NACLPORTS_INCLUDE}/glibc-compat
    NACLPORTS_CFLAGS+=" -I${GLIBC_COMPAT}"
    NACLPORTS_LDFLAGS+=" -lglibc-compat"
  fi

  DefaultConfigureStep
}

BuildStep() {
  ChangeDir ${SRC_DIR}
  # Git's build doesn't support building outside the source tree.
  # Do a clean to make rebuild after failure predictable.
  LogExecute make clean
  DefaultBuildStep
}

InstallStep() {
  MakeDir ${PUBLISH_DIR}
  local ASSEMBLY_DIR="${PUBLISH_DIR}/tar"

  export INSTALL_TARGETS="DESTDIR=${ASSEMBLY_DIR} install"
  DefaultInstallStep
}