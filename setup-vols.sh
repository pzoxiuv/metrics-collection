#!/bin/bash

script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
source ${script_dir}/include.sh

$DOCKERSUDO docker volume create --driver local --opt type=tmpfs --opt device=tmpfs --name shared-data-samil
$DOCKERSUDO docker volume create --driver local --opt type=tmpfs --opt device=tmpfs --name shared-data-cep
$DOCKERSUDO docker volume create --driver local --opt type=tmpfs --opt device=tmpfs --name shared-data-deepliif

$DOCKERSUDO docker run -d -v shared-data-samil:/data --runtime=nvidia -d xiedesaidocker/samil_data:latest sh -c "cp -r * /data/ && tail -f /dev/null"
$DOCKERSUDO docker run -d -v shared-data-cep:/data --runtime=nvidia -d xiedesaidocker/cep_data:latest sh -c "cp -r * /data/ && tail -f /dev/null"
$DOCKERSUDO docker run -d -v shared-data-deepliif:/datasets --runtime=nvidia -d xiedesaidocker/deepliif_data:latest sh -c "cp -r * /datasets/ && tail -f /dev/null"
