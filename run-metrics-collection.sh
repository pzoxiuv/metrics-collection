#!/bin/bash

script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
source ${script_dir}/include.sh

app=$1
gpu=$2
device=${3:-0}

mkdir -p output/${app}
chmod -R 777 output/${app}

if [ -z "${SKIPRUN+x}" ]; then
	extraargs=""
	if [ -f ${script_dir}/app-extraargs/${app} ]; then
		extraargs=$(cat ${script_dir}/app-extraargs/${app})
	fi
	$DOCKERSUDO docker run -d --rm --cap-add SYS_ADMIN -v ${CUDADIR}:${CONTAINER_CUDADIR} -v /opt/nvidia:/opt/nvidia --runtime=nvidia --gpus device=${device} -v /dev/shm:/dev/shm -v ${HOME}/output:/output -e app="${app}" -e gpu="${gpu}" -e MKL_SERVICE_FORCE_INTEL=1 -e MKL_THREADING_LAYER=GNU --name ${app} ${extraargs} $(cat ${script_dir}/app-images/${app}) tail -f /dev/null

	read -p "Press enter to continue"
fi

cp ${script_dir}/app-cmds/${app} output/${app}/app-cmd.sh

$DOCKERSUDO docker exec ${app} ${CONTAINER_CUDADIR}/bin/nsys profile -f true -o /output/${app}/${gpu}.${app}.nsys_prof bash /output/${app}/app-cmd.sh
read -p "Press enter to continue"

$DOCKERSUDO docker exec ${app} ${CONTAINER_CUDADIR}/bin/nsys stats --report gpusum --force-overwrite true --force-export true --format json --output /output/${app}/${gpu} /output/${app}/${gpu}.${app}.nsys_prof.nsys-rep

python3 ${script_dir}/parse-gpusum.py --in-file output/${app}/${gpu}_gpusum.json --out-dir /output/${app} --output-prefix ${gpu} --metrics-file ${script_dir}/metrics.json --app-cmdline "bash /output/${app}/app-cmd.sh" | sudo tee output/${app}/ncu-${app}.sh

$DOCKERSUDO docker exec ${app} bash /output/${app}/ncu-${app}.sh 2>&1 | tee out
${script_dir}/convert-ncu-output.sh output/${app}/

read -p "Press enter to continue"
docker stop ${app}
