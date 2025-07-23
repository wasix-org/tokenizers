#! /bin/bash

set -exuo pipefail

rm -rf build dist *.egg-info

source .cross-venv/bin/activate

PREV_DEFAULT=$(rustup default)
PREV_DEFAULT=${PREV_DEFAULT% (default)}

export WASIXCC_WASM_EXCEPTIONS=yes
export WASIXCC_PIC=yes
export CC_wasm32_wasmer_wasi_dl=wasixcc
export CXX_wasm32_wasmer_wasi_dl=wasix++

export PYO3_CROSS_LIB_DIR=$(realpath ../cpython-install/cpython/lib/)

pushd bindings/python

# Set this to the name of the wasix toolchain you have locally
# if you're not building your toolchain from source.
rustup override set wasix-dev
cargo update -p getrandom --precise 0.3.3
cargo update -p target-lexicon --precise 0.13.2
cargo update -p cc --precise 1.2.27
maturin build --target wasm32-wasmer-wasi-dl --release --interpreter python3.13 \
  --config 'patch.crates-io.getrandom.git="https://github.com/wasix-org/getrandom.git"' \
  --config 'patch.crates-io.getrandom.branch="wasix-0.3.3"' \
  --config 'patch.crates-io.target-lexicon.git="https://github.com/wasix-org/target-lexicon.git"' \
  --config 'patch.crates-io.target-lexicon.branch="wasix-0.13.2"' \
  --config 'patch.crates-io.cc.git="https://github.com/wasix-org/cc-rs.git"' \
  --config 'patch.crates-io.cc.branch="wasix-1.2.27"' \

cd target/wheels
mkdir -p temp
unzip tokenizers-0.21.4.dev0-cp39-abi3-any.whl -d temp
wasm-opt \
  ./temp/tokenizers/tokenizers.abi3.so \
  -o ./temp/tokenizers/tokenizers.abi3.so \
  --emit-exnref \
  --enable-threads --enable-mutable-globals --enable-bulk-memory \
  --enable-bulk-memory-opt --enable-exception-handling \
  --no-validation
rm tokenizers-0.21.4.dev0-cp39-abi3-any.whl
cd temp
zip -r ../tokenizers-0.21.4.dev0-cp39-abi3-any.whl ./
cd ..
rm -rf temp