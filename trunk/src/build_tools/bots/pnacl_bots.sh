#!/bin/bash
# Copyright (c) 2012 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#

######################################################################
# Notes on directory layout:
# makefile location (base_dir):  naclports/src
# bot script location:           naclports/src/build_tools/bots/
# toolchain injection point:     specified externally via NACL_SDK_ROOT.
######################################################################

set -o nounset
set -o errexit

readonly BASE_DIR="$(dirname $0)/../.."
cd ${BASE_DIR}

ERROR=0

export NACL_ARCH=pnacl
readonly PACKAGES=$(make works_for_pnacl_list)


StepConfig() {
  echo "@@@BUILD_STEP CONFIG"
  echo "BASE_DIR: ${BASE_DIR}"
  echo "PACKAGES:"
  for i in ${PACKAGES} ; do
    echo "    $i"
  done
}

StepInstallSdk() {
  build_tools/download_sdk.py -f pnaclsdk_linux
}

StepBuildEverything() {
  local messages=""

  make clean
  for i in ${PACKAGES} ; do
    if make $i ; then
      echo "naclports build SUCCEDED for $i"
    else
      echo "naclports build FAILED for $i"
      echo "@@@STEP_FAILURE@@@"
      messages="${messages}\nfailure: $i"
      ERROR=1
    fi
  done

  echo "@@@BUILD_STEP Summary@@@"
  if [[ ${ERROR} != 0 ]] ; then
    echo "@@@STEP_FAILURE@@@"
  fi
  echo -e "${messages}"
}

StepConfig
StepInstallSdk
StepBuildEverything

exit ${ERROR}