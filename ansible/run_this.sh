#!/usr/bin/env bash
#
# ./run_this.sh -e deploy_host='mtn-mia1' -e app_version='v92'
###################
export ANSIBLE_FORCE_COLOR=true
set -x

playbook="deploy.yml"

#---------------------------------------
# set vault's encryption password
#---------------------------------------

VAULT_PASSWORD_FILE=$HOME/.ssh/creds/ansible_vault.txt
VAULTOPTS="--vault-password-file=$VAULT_PASSWORD_FILE"

#set registry url to vagrant if not in jenkins-prime dind container
[[ -f /.dockerinit ]] && { 
  registry_url='docker-hub-vagrant.mtnsat.io'
} || {
  registry_url='docker-hub-int.mtnsat.io'
}

#starttime=$(date)

time ansible-playbook $VAULTOPTS "-e 'registry_url=${registry_url}'" "$@" "${playbook}"

