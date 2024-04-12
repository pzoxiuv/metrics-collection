### Setup

1. (Optional) Setup environment.  Installs helpful packages and configures ssh:
   `./setup-env.sh`

2. Pull images: `./pull-images.sh`

3. Setup nvidia Docker runtime: `./setup-nvidia-runtime.sh`

4. Setup volumes and data containers used by SAMIL, CEP, and DeepLIIF workloads:
    `./setup-vols.sh`

### Collecting metrics

Specify the app to be run and the name of the GPU.  The GPU name is used only 
for naming files (e.g., `v100_gpusum.json`) for organizational purposes.
`device num` is optional and specifies the device that will be assigned to the
workload container.  Default is 0.

    ./run-metrics-collection.sh <app name> <gpu name> [device num]

#### Environment variables

The following environment variables are used:

| Variable | Use | Default|
| :---------------- | :------ | :---- |
| `CUDADIR` | Specfies the directory containing the CUDA toolkit that will be mapped into the workload container. | /usr/local/cuda-12.2 |
| `CONTAINER_CUDADIR` |  Specifies the container directory where the CUDA toolkit directory will be mapped in.  Used together with `CUDADIR` to form the `docker run` argument `-v $CUDADIR:$CONTAINER_CUDADIR` | /usr/local/cuda-12.2 |
| `OUTPUT_DIR` |  Directory where output will be written to. | ${HOME}/output |
| `SKIPRUN` |  If set, `run-metrics-collection.sh` skips running the workload container. Useful if the container is already running. | (unset) |

Additionally, the existance of the file `.WAIT_FOR_INPUT` in the same directory
as `run-metrics-collection.sh` will make the script pause for user input after
starting the workload container, after the initial run of nsys, and before
deleting the workload container.  This can be useful for doing additional
configuration or setup on the container before running the workload, for
verifying that nsys and the workload ran successfully before proceeding, and 
for debugging on the workload container before it is deleted.

#### Collection workfloww

There are several steps to the metrics collection:

1. Run the workload container
2. Profile the workload with nsys
3. Generate a
[gpusum](https://docs.nvidia.com/nsight-systems/2022.3/UserGuide/index.html#gpusum)
report from the nsys profile
4. Parse the gpusum JSON report.  Generate a script that will run ncu,
profiling the top five kernels by time (%) and collecting the metrics listed in
`metrics.json`
5. Profile the workload with ncu, using the script created in step 4
6. Convert the ncu report to CSV
7. Stop the workload container

### App configuration

There are two directories with workload application configuration,
`app-images` and `app-cmds`.  For each workload, these directories
should contain a file with the same name as the workload.  In `app-images`,
this file contains the container image that is used to run the workload.
In `app-cmds`, this file contains the command line used within the workload
container to invoke the workload.

Optionally, a workload can have an additional file in the `app-extraargs`
directory.  The contents of this file will be added to the `docker run` command
when the workload container is created.  For example, if the workload `foo`
expects an additional environment variable set, `app-extraargs/foo` might
contain the line `-e bar=baz`, which will then be passed to `docker run` when
the workload container is created.
