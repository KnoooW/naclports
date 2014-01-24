#!/bin/bash
# Copyright (c) 2012 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


# Linux disk image
readonly LINUX_IMG_URL=http://storage.googleapis.com/nativeclient-mirror/nacl/bochs-linux-img.tar.gz
readonly LINUX_IMG_NAME=linux-img

BOCHS_EXAMPLE_DIR=${NACL_SRC}/ports/bochs
EXECUTABLES=bochs

ConfigureStep() {
  # export the nacl tools
  export CC=${NACLCC}
  export CXX=${NACLCXX}
  export AR=${NACLAR}
  export RANLIB=${NACLRANLIB}
  # path and package magic to make sure we call the right
  # sdl-config, etc.
  export PKG_CONFIG_PATH=${NACLPORTS_LIBDIR}/pkgconfig
  export PKG_CONFIG_LIBDIR=${NACLPORTS_LIBDIR}
  export CFLAGS=${NACLPORTS_CFLAGS}
  export CXXFLAGS=${NACLPORTS_CXXFLAGS}
  export LDFLAGS=${NACLPORTS_LDFLAGS}
  export PATH=${NACL_BIN_PATH}:${PATH};
  export PATH="${NACLPORTS_PREFIX_BIN}:${PATH}"

  export NACLBXLIBS="-lpthread"

  MakeDir ${NACL_PACKAGES_REPOSITORY}/${PACKAGE_NAME}/${NACL_BUILD_SUBDIR}
  ChangeDir ${NACL_PACKAGES_REPOSITORY}/${PACKAGE_NAME}/${NACL_BUILD_SUBDIR}

  EXE=${NACL_EXEEXT} LogExecute ../configure \
    --host=nacl \
    --prefix=${NACLPORTS_PREFIX} \
    --exec-prefix=${NACLPORTS_PREFIX} \
    --libdir=${NACLPORTS_LIBDIR} \
    --oldincludedir=${NACLPORTS_INCLUDE} \
    --with-x=no \
    --with-x11=no \
    --with-sdl=yes \
    --with-gnu-ld
}

ImageExtractStep() {
  Banner "Untaring $1 to $2"
  ChangeDir ${NACL_PACKAGES_REPOSITORY}
  Remove $2
  if [ $OS_SUBDIR = "windows" ]; then
    tar --no-same-owner -zxf ${NACL_PACKAGES_TARBALLS}/$1
  else
    tar zxf ${NACL_PACKAGES_TARBALLS}/$1
  fi
}

InstallStep() {
  BOCHS_DIR=${NACL_PACKAGES_REPOSITORY}/${PACKAGE_NAME}
  BOCHS_BUILD=${BOCHS_DIR}/${NACL_BUILD_SUBDIR}

  ChangeDir ${BOCHS_DIR}
  mkdir -p img/usr/local/share/bochs/
  cp -r ${NACL_PACKAGES_REPOSITORY}/${LINUX_IMG_NAME} img/
  mv img/linux-img/bochsrc old-bochsrc
  cp ${START_DIR}/bochsrc img/linux-img/bochsrc
  cp -r ${BOCHS_DIR}/bios/VGABIOS-lgpl-latest img/
  cp -r ${BOCHS_DIR}/bios/BIOS-bochs-latest img/
  cp -r ${BOCHS_DIR}/msrs.def img/

  MakeDir ${PUBLISH_DIR}

  cd img
  tar cf ${PUBLISH_DIR}/img.tar .
  cd ..

  cp ${START_DIR}/bochs.html ${PUBLISH_DIR}
  cp ${BOCHS_BUILD}/bochs ${PUBLISH_DIR}/bochs_${NACL_ARCH}${NACL_EXEEXT}

  if [ ${NACL_ARCH} = pnacl ]; then
    sed -i.bak 's/x-nacl/x-pnacl/g' ${PUBLISH_DIR}/bochs.html
  fi

  pushd ${PUBLISH_DIR}
  LogExecute python ${NACL_SDK_ROOT}/tools/create_nmf.py \
      bochs*${NACL_EXEEXT} \
      -s . \
      -o bochs.nmf
  popd
}

CustomCheck() {
  # verify sha1 checksum for tarball
  if ${SHA1CHECK} <$1 &>/dev/null; then
    return 0
  else
    return 1
  fi
}

ImageDownloadStep() {
  cd ${NACL_PACKAGES_TARBALLS}
  # if matching tarball already exists, don't download again
  if ! CustomCheck $3; then
    Fetch $1 $2.tar.gz
    if ! CustomCheck $3 ; then
       Banner "${PACKAGE_NAME} failed checksum!"
       exit -1
    fi
  fi
}

FetchLinuxStep() {
  Banner "FetchLinuxStep"
  ARCHIVE_NAME=$2.tar.gz
  SHA1=${BOCHS_EXAMPLE_DIR}/$2/$2.sha1
  ImageDownloadStep $1 $2 ${SHA1}
  ImageExtractStep ${ARCHIVE_NAME} $2
  unset ARCHIVE_NAME
}

DownloadStep() {
  DefaultDownloadStep
  FetchLinuxStep ${LINUX_IMG_URL} ${LINUX_IMG_NAME}
}
