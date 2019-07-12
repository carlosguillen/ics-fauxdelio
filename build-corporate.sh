#!/usr/bin/env bash

# Build script for CI running inside the corporate network

#---------------------------------------
# VARS
#---------------------------------------
PULL_REGISTRY_URL='docker.mtnsat.io'
PUSH_REGISTRY_URL='gee-docker.mtnsat.io'
APP_NAME='fauxdelio'
in_docker_container='unknown'
#docker_hub_vagrant=  #set this externally to push/pull to ansible/vagrant instance of docker_hub

#---------------------------------------
# test if in docker container
#---------------------------------------
[[ -f /.dockerinit ]] && {
  in_docker_container='true'
}

#---------------------------------------
# Pull the last images
# if on jenkins or docker_hub_vagrant true
#---------------------------------------
app_exists=$(docker search ${PULL_REGISTRY_URL}/${APP_NAME} | sed -n '1!p')

  #do not pull if the registry does not have it yet
[[ -z $app_exists ]] || {
  # Pull the latest image to ensure that the build cache is primed
  echo "Pulling latest image ${PULL_REGISTRY_URL}"/"${APP_NAME}"
  docker pull "${PULL_REGISTRY_URL}"/"${APP_NAME}"
}

#---------------------------------------
# Log recent git commits to Changes.txt file
#---------------------------------------
git log --graph --pretty --abbrev-commit --since="2016-01-01" > Changes.txt

#---------------------------------------
# Build and tag the image
#---------------------------------------
#if no build_number (because we're running locally, not in jenkins),
#then assign 'test' to build_number
if [[ -z $BUILD_NUMBER ]]; then
    echo "No build number, using test"
    BUILD_NUMBER='Test-'"$(date +%y%m%d-%H%M%S-%N)"
else
    [[ $GIT_BRANCH != *"master"* ]]  && {
        BUILD_NUMBER="$GIT_BRANCH-$BUILD_NUMBER"
    }
fi

echo "Build num:${BUILD_NUMBER}"

echo "{ \"build_number\": \"${BUILD_NUMBER}\" }" > build_number.json

# build image
docker build -t "${PUSH_REGISTRY_URL}"/"${APP_NAME}":v"${BUILD_NUMBER}" .
docker tag "${PUSH_REGISTRY_URL}"/"${APP_NAME}":v"${BUILD_NUMBER}" "${PUSH_REGISTRY_URL}"/"${APP_NAME}":latest 

echo "Pushing to ${PUSH_REGISTRY_URL}"
docker push "${PUSH_REGISTRY_URL}"/"${APP_NAME}":v"${BUILD_NUMBER}"
docker push "${PUSH_REGISTRY_URL}"/"${APP_NAME}":latest

# clean up by removing BUILD_NUMBER tagged image
docker rmi -f "${PUSH_REGISTRY_URL}"/"${APP_NAME}":v"${BUILD_NUMBER}"

