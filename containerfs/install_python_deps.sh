#!/bin/bash
# Copyright 2019-2025 AstroLab Software
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

set -e

message_help="""
Install Python dependencies for fink-broker through pip

Usage:
    ./install_python_deps.sh [OPTIONS]

OPTIONS:
    -s, --survey SURVEY     Survey: rubin or ztf (auto-detected from current directory if not specified)
    --science              Install all dependencies including science packages (default)
    --noscience            Install only base and test dependencies
    -v, --verbose          Enable verbose output for debugging
    -h, --help             Show this help message

Examples:
    ./install_python_deps.sh --survey ztf --science
    ./install_python_deps.sh -s rubin --noscience --verbose
"""

# Default values
SURVEY=$(basename "$PWD")
MODE="science"
VERBOSE=false

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--survey)
            SURVEY="$2"
            shift 2
            ;;
        --science)
            MODE="science"
            shift
            ;;
        --noscience)
            MODE="noscience"
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo -e "$message_help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo -e "$message_help"
            exit 1
            ;;
    esac
done

# Enable verbose output if requested
if [[ "$VERBOSE" == true ]]; then
    set -x
fi

echo "Installing Python dependencies for survey: $SURVEY, mode: $MODE"

# Validate survey
if [[ ! "$SURVEY" =~ ^(rubin|ztf)$ ]]; then
    echo "Error: Invalid survey '$SURVEY'. Must be 'rubin' or 'ztf'"
    echo -e "$message_help"
    exit 1
fi

# Set requirements path based on fink-broker installation
REQUIREMENTS_PATH="${FINK_BROKER_ROOT:-/opt/fink-broker}/${SURVEY}/deps"

# Debug information in verbose mode
if [[ "$VERBOSE" == true ]]; then
    echo "DEBUG: Current working directory: $(pwd)"
    echo "DEBUG: HOME directory: ${HOME}"
    echo "DEBUG: Fink-broker directory: ${FINK_BROKER_ROOT:-/opt/fink-broker}"
    echo "DEBUG: Requirements path: ${REQUIREMENTS_PATH}"
    echo "DEBUG: Available files:"
    ls -la
    echo "DEBUG: Available requirements files in ${REQUIREMENTS_PATH}:"
    ls -la "${REQUIREMENTS_PATH}" 2>/dev/null || echo "Requirements path not found"
    echo "DEBUG: Python version: $(python --version 2>&1 || echo 'Python not found')"
    echo "DEBUG: Pip version: $(pip --version 2>&1 || echo 'Pip not found')"
    echo "DEBUG: Requirements files status:"
    for f in "${REQUIREMENTS_PATH}"/requirements*.txt; do
        if [[ -f "$f" ]]; then
            echo "  - $f ($(wc -l < "$f") lines)"
        else
            echo "  - $f (not found)"
        fi
    done
fi

# Install base dependencies (always installed)
echo "Installing pre-requisites"
pip install --no-cache-dir --upgrade pip setuptools wheel

if [[ "$MODE" == "noscience" ]]; then
    echo "Installing requirements (base + test) together to avoid dependency conflicts..."
    pip install --no-cache-dir -r "${REQUIREMENTS_PATH}/requirements.txt" -r "${REQUIREMENTS_PATH}/requirements-test.txt"
elif [[ "$MODE" == "science" ]]; then
    # Install science dependencies for science mode
    echo "Installing requirements (base + test + science) together to avoid dependency conflicts..."
    pip install --no-cache-dir -r "${REQUIREMENTS_PATH}/requirements.txt" -r "${REQUIREMENTS_PATH}/requirements-test.txt" -r "${REQUIREMENTS_PATH}/requirements-science.txt"

    echo "Installing science dependencies without deps..."
    pip install --no-cache-dir -r "${REQUIREMENTS_PATH}/requirements-science-no-deps.txt" --no-deps

    # ZTF-specific: dustmaps initialization
    if [[ "$SURVEY" == "ztf" ]]; then
        echo "Initializing dustmaps for ZTF..."
        python -c "
from dustmaps.config import config
import dustmaps.sfd
import json
import requests
import os

# Copied from website https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/EWCNL5
fallback_url = 'https://dvn-cloud-iqss.s3.amazonaws.com/10.7910/DVN/EWCNL5/157bb43e038-2856c7e44170?response-content-disposition=attachment%3B%20filename%2A%3DUTF-8%27%27SFD_dust_4096_ngp.fits&response-content-type=application%2Ffits&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20260814T093733Z&X-Amz-SignedHeaders=host&X-Amz-Credential=AKIAZT3GWQ6FKBSH5I56%2F20260814%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Expires=3600&X-Amz-Signature=8923c750d5940b61342b534ede2404edb2648537ad2ada0f02b38787c97a4740'

fname = '/opt/fink-broker/miniconda/lib/python3.9/site-packages/dustmaps/data/sfd/SFD_dust_4096_ngp.fits'
try:
    dustmaps.sfd.fetch()
except json.decoder.JSONDecodeError:
    r = requests.get(fallback_url)
    
    # Make sure the directory it's going into exists
    dir_name = os.path.dirname(fname)
    if not os.path.exists(dir_name):
        os.makedirs(dir_name)

    with open(fname, 'wb') as f:
        f.write(r.content)
"
    fi
fi

echo "Python dependencies installation completed for $SURVEY (mode: $MODE)"
