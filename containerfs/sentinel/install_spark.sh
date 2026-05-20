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
Download and install locally Apache Spark \n\n
Usage:\n
    ./install_spark.sh [--spark-version] [--hadoop-version] [-h] \n\n

Specify the Spark version with --spark-version, and the hadoop version with --hadoop-version.\n
e.g. ./install_spark --spark-version 2.4.7 --hadoop-version hadoop2.7\n
e.g. ./install_spark --spark-version 3.1.3 --hadoop-version hadoop3.2\n
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
    --spark-version)
        if [[ $2 == "" ]]; then
          echo "$1 requires an argument" >&2
          exit 1
        fi
        SPARK_VERSION="$2"
        shift 2
        ;;
    --hadoop-version)
        if [[ $2 == "" ]]; then
          echo "$1 requires an argument" >&2
          exit 1
        fi
        HADOOP_VERSION="$2"
        shift 2
        ;;
  esac
done

if [[ $SPARK_VERSION == "" ]]; then
  echo "You need to specify the Spark version with the option --spark-version."
  exit
fi

if [[ $HADOOP_VERSION == "" ]]; then
  echo "You need to specify the Hadoop version with the option --hadoop-version."
  exit
fi

echo "Downloading spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz"
curl -fsSL -C - \
  --retry 5 --retry-delay 3 --retry-all-errors \
  --connect-timeout 30 --max-time 600 \
  -o "spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz" \
  "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz"
tar -xf spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz -C ${FINK_BROKER_ROOT}
rm spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz

export SPARK_HOME=$FINK_BROKER_ROOT/spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}

cat > ${SPARK_HOME}/conf/spark-defaults.conf <<EOF
spark.yarn.jars=${SPARK_HOME}/jars/*.jar
spark.driver.extraJavaOptions=-Dlog4j.logger.org.apache.hadoop.util.NativeCodeLoader=ERROR
spark.executor.extraJavaOptions=-Dlog4j.logger.org.apache.hadoop.util.NativeCodeLoader=ERROR
EOF

if [[ $SPARK_VERSION == 2* ]]; then
  echo "ARROW_PRE_0_15_IPC_FORMAT=1" > ${SPARK_HOME}/conf/spark-env.sh
fi
