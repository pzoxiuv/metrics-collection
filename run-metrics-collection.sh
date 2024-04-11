#!/bin/bash

script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
source ${script_dir}/include.sh

if [ "$#" -lt 2 ]; then
	echo "Usage: $0 <app name> <GPU model> [GPU device number]"
	exit
fi

app=$1
gpu=$2
device=${3:-0}
output_dir=${OUTPUT_DIR:-${HOME}/output}

mkdir -p ${output_dir}/${app}
chmod -R 777 ${output_dir}/${app}

if [ -z "${SKIPRUN+x}" ]; then
	extraargs=""
	if [ -f ${script_dir}/app-extraargs/${app} ]; then
		extraargs=$(cat ${script_dir}/app-extraargs/${app})
	fi
	image=$(cat ${script_dir}/app-images/${app})
	$DOCKERSUDO docker run -d \
			       --rm \
			       --cap-add SYS_ADMIN \
			       --runtime=nvidia \
			       --gpus device=${device} \
			       --name ${app} \
			       ${extraargs} \
			       -v ${CUDADIR}:${CONTAINER_CUDADIR} \
			       -v /opt/nvidia:/opt/nvidia \
			       -v /dev/shm:/dev/shm \
			       -v ${output_dir}:/output \
			       -e app="${app}" \
			       -e gpu="${gpu}" \
			       -e MKL_SERVICE_FORCE_INTEL=1 \
			       -e MKL_THREADING_LAYER=GNU \
			       ${image} \
			       tail -f /dev/null

	wait_to_continue
fi

cp ${script_dir}/app-cmds/${app} ${output_dir}/${app}/app-cmd.sh

$DOCKERSUDO docker exec ${app} \
			${CONTAINER_CUDADIR}/bin/nsys profile \
			-f true \
			-o /output/${app}/${gpu}.${app}.nsys_prof \
			bash /output/${app}/app-cmd.sh

wait_to_continue

$DOCKERSUDO docker exec ${app} \
			${CONTAINER_CUDADIR}/bin/nsys stats \
			--report gpusum \
			--force-overwrite true \
			--force-export true \
			--format json \
			--output /output/${app}/${gpu} \
			/output/${app}/${gpu}.${app}.nsys_prof.nsys-rep

if [ $app = "rodinia" ]; then
	num_kernels=-1
else
	num_kernels=5
fi

python3 ${script_dir}/parse-gpusum.py \
	--in-file ${output_dir}/${app}/${gpu}_gpusum.json \
	--out-dir /output/${app} \
	--output-prefix ${gpu} \
	--metrics-file ${script_dir}/metrics.json \
	--app-cmdline "bash /output/${app}/app-cmd.sh" \
	--num-kernels ${num_kernels} \
	| tee ${output_dir}/${app}/ncu-${app}.sh

$DOCKERSUDO docker exec ${app} \
			bash /output/${app}/ncu-${app}.sh 2>&1 \
			| tee ${output_dir}/${app}/ncu-out

${script_dir}/convert-ncu-output.sh ${output_dir}/${app}/

wait_to_continue

docker stop ${app}
