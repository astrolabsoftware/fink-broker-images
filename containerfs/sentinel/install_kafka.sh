#!/bin/bash
# Copyright 2022 AstroLab Software
# Author: Abhishek Chauhan, Julien Peloton
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
Download and install locally Apache Kafka\n\n
Usage:\n
    ./install_kafka.sh [--version] [-h] \n\n

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
        KAFKA_VERSION="$2"
        shift 2
        ;;
  esac
done

if [[ $KAFKA_VERSION == "" ]]; then
  echo "You need to specify the Kafka version with the option --version."
  exit
fi

<<<<<<< HEAD
curl -fL --connect-timeout 15 --max-time 300 --retry 5 --retry-delay 5 \
    https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_2.12-${KAFKA_VERSION}.tgz -o kafka.tgz \
    && tar -xzf kafka.tgz -C ${FINK_BROKER_ROOT} && rm kafka.tgz

# override default server.properties (setting num.partition=10)
echo " Copying custom configuration..."
curl -s https://raw.githubusercontent.com/apache/kafka/${KAFKA_VERSION}/config/server.properties  \
 | sed 's/^num.partitions=.*/num.partitions=10/' \
 > "${FINK_BROKER_ROOT}/kafka_2.12-${KAFKA_VERSION}/config/server.properties"
=======
echo "Downloading kafka_2.12-${KAFKA_VERSION}.tgz"
curl -fsSL --insecure \
  --retry 5 --retry-delay 3 --retry-all-errors \
  --connect-timeout 30 --max-time 600 \
  -o "kafka_2.12-${KAFKA_VERSION}.tgz" \
  "https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_2.12-${KAFKA_VERSION}.tgz"
tar -zxvf kafka_2.12-${KAFKA_VERSION}.tgz -C ${FINK_BROKER_ROOT}
rm kafka_2.12-${KAFKA_VERSION}.tgz

# override default server.properties (setting num.partition=10)
echo " Copying custom configuration..."
curl -s https://raw.githubusercontent.com/apache/kafka/${KAFKA_VERSION}/config/server.properties  \
 | sed 's/^num.partitions=.*/num.partitions=10/' \
 > "${FINK_BROKER_ROOT}/kafka_2.12-${KAFKA_VERSION}/config/server.properties"
>>>>>>> caa317e (Replace wget with curl in install scripts for better reliability and GHA compatibility)
