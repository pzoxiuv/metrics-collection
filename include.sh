#!/bin/bash

if id -nG "$USER" | grep -qw docker; then
	DOCKERSUDO=""
else
	DOCKERSUDO="sudo"
fi

CUDADIR=${CUDADIR:-/usr/local/cuda-12.2}
CONTAINER_CUDADIR=${CONTAINER_CUDADIR:-/usr/local/cuda-12.2}
