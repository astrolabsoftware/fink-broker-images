#!/bin/bash
# Copyright 2022 AstroLab Software
# Author: Julien Peloton
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euxo pipefail

message_help="""
Download and install locally Apache HBase, and launch it \n\n
Usage:\n
    ./install_hbase.sh [--version] [-h] \n\n

Specify the version with --version.\n
Use -h to display this help.
"""

# Show help if no arguments is given
if [[ $1 == "" ]]; then
  echo -e $message_help
  exit 1
fi

# Grab the command line arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h)
        echo -e $message_help
        exit
        ;;
    --version)
        if [[ $2 == "" ]]; then
          echo "$1 requires an argument" >&2
          exit 1
        fi
        HBASE_VERSION="$2"
        shift 2
        ;;
  esac
done

if [[ $HBASE_VERSION == "" ]]; then
  echo "You need to specify the HBase version with the option --version."
  exit
fi

curl -fL --connect-timeout 15 --max-time 300 --retry 5 --retry-delay 5 \
    https://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz -o hbase.tgz \
    && tar -xzf hbase.tgz -C ${PWD} && rm hbase.tgz
