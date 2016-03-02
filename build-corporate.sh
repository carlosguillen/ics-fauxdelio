#!/usr/bin/env bash

# Build script for CI running inside the corporate network

#---------------------------------------
# VARS
#---------------------------------------
REGISTRY_URL='docker-hub-int.mtnsat.io'
APP_NAME='fauxdelio'
in_docker_container='unknown'
#docker_hub_vagrant=  #set this externally to push/pull to ansible/vagrant instance of docker_hub

#---------------------------------------
# test if in docker container
#---------------------------------------
[[ -f /.dockerinit ]] && {
  in_docker_container='true'
} || {
  in_docker_container='false'
  docker_hub_vagrant='true'
}

#---------------------------------------
# if docker_hub_vagrant set, push and pull locally
#---------------------------------------
[[ $docker_hub_vagrant == 'true' ]] && {
  #REGISTRY_URL='192.168.60.52'
  #REGISTRY_URL='docker-hub-vagrant.mtnsat.io'
  echo "$REGISTRY_URL"
}

#---------------------------------------
# Pull the last images
# if on jenkins or docker_hub_vagrant true
#---------------------------------------
{ [[ $in_docker_container == 'true' ]] || [[ $docker_hub_vagrant == 'true' ]] ;} && {
   app_exists=$(curl -s -X GET https://${REGISTRY_URL}/v1/search?q=${APP_NAME} | perl -lane 'print $1 if /.*results.:.*(\[.*\])}/')

  #do not pull if the registry does not have it yet
  [[ $app_exists == '[]' ]] || {
    # Pull the latest image to ensure that the build cache is primed
    echo "Pulling latest image ${REGISTRY_URL}"/"${APP_NAME}"
    docker pull "${REGISTRY_URL}"/"${APP_NAME}"
  }
}

#---------------------------------------
# Build and tag the image
#---------------------------------------
#if no build_number (because we're running locally, no in jenkins),
#then assign 'test' to build_number
[[ $BUILD_NUMBER ]] || {
  BUILD_NUMBER='Test-'"$(date +%y%m%d-%H%M%S-%N)"
}
echo "Build num:${BUILD_NUMBER}"

echo "{ \"build_number\": \"${BUILD_NUMBER}\" }" > build_number.json

#---------------------------------------
# include build number in the image as a normal text file
# the app can use build number information in its health checks
#---------------------------------------

# build images
docker build -t "${REGISTRY_URL}"/"${APP_NAME}":v"${BUILD_NUMBER}" .
docker build -t "${REGISTRY_URL}"/"${APP_NAME}":latest .

{ [[ $in_docker_container == 'true' ]] || [[ $docker_hub_vagrant == 'true' ]] ;} && {
  echo "Pushing to ${REGISTRY_URL}"
  docker push "${REGISTRY_URL}"/"${APP_NAME}":v"${BUILD_NUMBER}"
  docker push "${REGISTRY_URL}"/"${APP_NAME}":latest
}

# remove BUILD_NUMBER tagged imagess as they are not needed anymore
docker rmi -f "${REGISTRY_URL}"/"${APP_NAME}":v"${BUILD_NUMBER}"

