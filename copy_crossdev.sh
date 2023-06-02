#!/bin/bash
# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Copies the crossdev config into the toolchains overlay.

set -eu -o pipefail

if [[ ! -d /etc/portage ]]; then
  echo "/etc/portage was not found, are you in the chroot?" >&2
  exit 1
fi

PROFILE="$(realpath --relative-to . "$(dirname "$0")")/profiles/base"
mkdir -p "${PROFILE}"

for SRC in \
    /etc/portage/profile/package.use.mask \
    /etc/portage/profile/package.use.force \
    /etc/portage/package.accept_keywords \
    /etc/portage/package.use
do
  DEST="${PROFILE}/$(basename "${SRC}")"
  mkdir -p "${DEST}"
  find "${SRC}" -iname 'cross-*' \
    -exec cp -vft "${DEST}" '{}' +
done

# Profiles don't support the `env` feature, but they do support `bashrc` so we
# use that instead.
mkdir -p "${PROFILE}/bashrc" "${PROFILE}/package.bashrc"

find /etc/portage/package.env -iname 'cross-*' \
  -exec cp -vft "${PROFILE}/package.bashrc" '{}' +

while read -r TOOLCHAIN; do
  cp -rfv "/etc/portage/env/${TOOLCHAIN}" "${PROFILE}/bashrc/"

  # We only want the env files to be apply before src_setup because some ebuilds
  # modify some of the multilib variables in src_setup and we don't want to
  # override them.
  # shellcheck disable=SC2016
  find "${PROFILE}/bashrc/${TOOLCHAIN}" -iname '*.conf' \
    -exec sed -i -E \
      -e '1 i\if [[ "${EBUILD_PHASE}" == "setup" ]]; then' \
      -e '$afi' \
      '{}' +
done < <(find /etc/portage/env -maxdepth 1 -iname 'cross-*' -printf '%P\n')
