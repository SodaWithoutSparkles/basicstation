#!/bin/bash

# --- Revised 3-Clause BSD License ---
# Copyright Semtech Corporation 2022. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the Semtech corporation nor the names of its
#       contributors may be used to endorse or promote products derived from this
#       software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL SEMTECH CORPORATION. BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -e
cd $(dirname $0)

lgwversion="V${lgwversion:-2.1.0}"
# Using brocaar's fork for compatibility with SX1302 without temperature sensors
# Verified working as of 587f4c28ecab91a96e65ac3b2686101a2b768727 
lgwrepo="${lgwrepo:-https://github.com/brocaar/sx1302_hal.git}"
lgwref="${lgwref:-master}"

if [[ ! -d git-repo ]]; then
    git clone "${lgwrepo}" git-repo
else
    (cd git-repo && git remote set-url origin "${lgwrepo}")
fi

if [[ -z "${platform}" ]] || [[ -z "${variant}" ]]; then
    echo "Expecting env vars platform/variant to be set - comes naturally if called from a makefile"
    echo "If calling manually try: variant=std platform=corecell $0"
    exit 1
fi

platform_dir="platform-${platform}"
platform_stamp="${platform_dir}/.lgw-source"
desired_source="repo=${lgwrepo};ref=${lgwref}"

if [[ -d "${platform_dir}" ]] && [[ (! -f "${platform_stamp}") || "$(cat "${platform_stamp}")" != "${desired_source}" ]]; then
    echo "Recreating ${platform_dir}: source/ref changed"
    rm -rf "${platform_dir}"
fi

if [[ ! -d "${platform_dir}" ]]; then
    (cd git-repo && git fetch --tags --quiet && git checkout "${lgwref}")
    git clone git-repo "${platform_dir}"

    cd "${platform_dir}"
    git checkout "${lgwref}"
    if [ -f ../${lgwversion}-${platform}.patch ]; then
        echo "Applying ${lgwversion}-${platform}.patch ..."
        git apply ../${lgwversion}-${platform}.patch
    fi
    echo "${desired_source}" > .lgw-source
fi
