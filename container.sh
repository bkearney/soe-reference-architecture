#! /bin/bash

# this is step where we expect to have an already installed satellite 6 and create the configuration for all further steps, the main org and subscriptions

# TODO short desc and outcome of this step

DIR="$PWD"
source "${DIR}/common.sh"

# create org
hammer organization create --name "$ORG" --label "$ORG_LABEL" --description "$ORG_DESCRIPTION"

# create one lifecycle environment
hammer lifecycle-environment create --organization "$ORG" --name "DEV" --description "development" --prior "Library"

# create a container product
hammer product create --name='containers' --organization="$ORG"
hammer repository create --name='rhel' --organization="$ORG" --product='containers' --content-type='docker' --url='https://registry.access.redhat.com' --docker-upstream-name='rhel'
hammer repository create --name='wordpress' --organization="$ORG" --product='containers' --content-type='docker' --url='https://registry.hub.docker.com' --docker-upstream-name='wordpress'
hammer repository create --name='mysql' --organization="$ORG" --product='containers' --content-type='docker' --url='https://registry.hub.docker.com' --docker-upstream-name='mysql'

# Sync the images
hammer product synchronize --organization "$ORG" --name "containers"

hammer content-view create --name "registry" --description "Sample Registry" --organization "$ORG"
hammer content-view add-repository --organization "$ORG" --name "registry" --repository "rhel" --product "containers"
hammer content-view add-repository --organization "$ORG" --name "registry" --repository "mysql" --product "containers"
hammer content-view add-repository --organization "$ORG" --name "registry" --repository "wordpress" --product "containers"

hammer content-view publish --organization "$ORG" --name "registry" 
