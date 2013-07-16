#!/bin/bash
# Copyright (c) 2013 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

source pkg_info
source ../../build_tools/common.sh

EXECUTABLES=python.nexe
# Currently this package only builds on linux.
# The build relies on certain host binaries and pythong's configure
# requires us to sett --build= as well as --host=.
HERE=$(cd "$(dirname "$BASH_SOURCE")" ; pwd)

BuildHostPython() {
  ChangeDir ${NACL_PACKAGES_REPOSITORY}/${PACKAGE_DIR}
  MakeDir build-nacl-host
  ChangeDir build-nacl-host
  if [ -f python -a -f Parser/pgen ]; then
    return
  fi
  # Reset CFLAGS and LDFLAGS when configuring the host
  # version of python since they hold values designed for
  # building for NaCl.
  CFLAGS="" LDFLAGS="" LogExecute ../configure
  LogExecute make -j${OS_JOBS} python Parser/pgen
}

CustomConfigureStep() {
  BuildHostPython
  export CROSS_COMPILE=true
  # We pre-seed configure with certain results that it cannot determine
  # since we are doing a cross compile.  The $CONFIG_SITE file is sourced
  # by configure early on.
  export CONFIG_SITE=${HERE}/config.site
  # Disable ipv6 since configure claims it requires a working getaddrinfo
  # which we do not provide.  TODO(sbc): remove this once nacl_io supports
  # getaddrinfo.
  EXTRA_CONFIGURE_ARGS="--disable-ipv6"
  EXTRA_CONFIGURE_ARGS+=" --with-suffix=.nexe"
  EXTRA_CONFIGURE_ARGS+=" --build=x86_64-linux-gnu"
  export MAKEFLAGS="PGEN=../build-nacl-host/Parser/pgen"
  export LIBS="-lc -lnosys"
  DefaultConfigureStep
}

CustomTestStep() {
  WriteSelLdrScript python python.nexe
}

CustomPackageInstall() {
  DefaultPreInstallStep
  DefaultDownloadStep
  DefaultExtractStep
  DefaultPatchStep
  CustomConfigureStep
  DefaultBuildStep
  DefaultTranslateStep
  DefaultValidateStep
  CustomTestStep
  DefaultInstallStep
}

CustomPackageInstall
exit 0