#!/bin/bash

script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
source ${script_dir}/include.sh

$DOCKERSUDO docker image pull ubuntu:22.04 &
i=0
for f in `find ${script_dir}/app-images/ -type f`; do
	$DOCKERSUDO docker image pull $(cat $f) &
	i=$((i+1))
	if [ $i -gt 2 ]; then 
		i=0
		wait
	fi
done
