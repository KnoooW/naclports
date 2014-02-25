#!/bin/bash
# Copyright (c) 2011 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

EXTRA_CMAKE_ARGS="-DBOX2D_BUILD_EXAMPLES=OFF"

TestStep() {
  ChangeDir ${BUILD_DIR}/HelloWorld
  RunSelLdrCommand HelloWorld
}