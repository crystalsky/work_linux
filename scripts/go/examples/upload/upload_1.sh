#!/bin/bash

# mkdir -p dist
# wget -O ./dist/go_mod_20260929_221537_arm64.tar.gz http://app.cdvire.cn/02_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/go/go_mod_20260929_221537_arm64.tar.gz
# wget -O ./dist/go_mod_20260929_221013_amd64.tar.gz http://app.cdvire.cn/02_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/go/go_mod_20260929_221013_amd64.tar.gz

GITEA_TOKEN=a7a1970cc236474494c48fdbe43e72ff37629614 \
  bash ../../gitea_go_upload.sh \
    -u http://conan_repos.cdvire.cn -o go_dev --user go_dev -j 8 --strict \
    ../../dist/go_mod_20260930_191526_amd64.tar.gz \
    ../../dist/go_mod_20260930_191526_arm64.tar.gz

