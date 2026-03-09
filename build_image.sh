#!/bin/bash

# set variables
D_IMAGE_VERSION=10.0.24.2
_TAG=alpine-glpi
BASE_IMAGE=alpine:3.22
GLPI_VERSION=10.0.24
PHP_VERSION=83
#ALPINE_VERSION=3.23


# build glpi docker
# docker build -t johann8/${_TAG}:${D_IMAGE_VERSION} . 2>&1 | tee ./build.log
docker build \
  --build-arg=BASE_IMAGE=${BASE_IMAGE} \
  --build-arg=GLPI_VERSION=${GLPI_VERSION} \
  --build-arg=PHP_VERSION=${PHP_VERSION} \
  --platform=linux/amd64 \
  --tag=johann8/${_TAG}:${D_IMAGE_VERSION} \
  --file=./Dockerfile . 2>&1 | tee ./build.log


_BUILD=$?

# Check
if ! [ ${_BUILD} = 0 ]; then
   echo "ERROR: Docker Image build was not successful"
   exit 1
else
   echo "Docker Image build successful"
   docker images -a
   docker tag johann8/${_TAG}:${D_IMAGE_VERSION} johann8/${_TAG}:latest
fi

#push image to dockerhub
if [ ${_BUILD} = 0 ]; then
   echo "Pushing docker images to dockerhub..."
   docker push johann8/${_TAG}:${D_IMAGE_VERSION}
   docker push johann8/${_TAG}:latest
   _PUSH=$?
   docker images -a |grep glpi
fi

#
### show
#
if [ ${_PUSH} = 0 ]; then
   echo "Pushing docker image \"${_TAG}\" was successfull."
else
   echo "ERROR: Pushing docker image \"${_TAG}\" was not successfull."
fi

# delete build docker image
if [ ${_PUSH} = 0 ]; then
   echo "Deleting docker images..."
   docker rmi johann8/${_TAG}:${D_IMAGE_VERSION}
   docker rmi johann8/${_TAG}:latest
   #docker rmi $(docker images -f "dangling=true" -q)
   docker images -a
fi
