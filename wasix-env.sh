#! /bin/bash

set -exuo pipefail

rm -rf .native-venv .cross-venv build

python3.13 -m venv ./.native-venv
source ./.native-venv/bin/activate
pip install crossenv pycparser build cffi

python -m crossenv ../cpython-install/cpython/bin/python3.wasm ./.cross-venv --cc wasixcc --cxx wasix++
source .cross-venv/bin/activate
pip install cython build maturin typing-extensions

# maturin seems to like to install with a .wasm extension for some reason, which we don't need
rm .cross-venv/cross/bin/maturin.wasm
# instead we put in a patched version with WASIX compatibility
cp ../python-wasix-binaries/bin/maturin .cross-venv/cross/bin/maturin
