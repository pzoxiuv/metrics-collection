#!/bin/bash

script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
source ${script_dir}/include.sh

for f in $1/*ncu-rep; do ${CUDADIR}/bin/ncu --import $f --csv | tee "${f%.*}.csv"; done
