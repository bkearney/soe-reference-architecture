#! /bin/bash

#
# this script automatically does the setup documented in the reference architecture "10 steps to create a SOE"
# 


# TODO short desc and outcome of this step

# latest version in github: https://github.com/dirkherrmann/soe-reference-architecture

DIR="$PWD"
source "${DIR}/common.sh"

# TODO DOCUMENTATION: now the CCV creation works. Maybe a little bit misleading is the component IDs you need to provide are *NOT* the *CV* IDs but their *VERSION IDS*
# I will document it inside the ref arch especially in step9 where I'm playing around with CCV lifecycle topics

# TODO check if create a function in common.sh with param cv-name and getting back the highest version ID

# since we need our core build CV IDs more than once let's use variables for them
# note: we don't need to CV IDs but the VERSION IDs of most current versions for our CCV creation
if [ "$RHEL6_ENABLED" -eq 1 ]
then
	export RHEL6_CB_VID=`get_latest_version cv-os-rhel-6Server`
	echo "Identified VERSION ID ${RHEL6_CB_VID} as most current version of our RHEL6 Core Build"
fi

export RHEL7_CB_VID=`get_latest_version cv-os-rhel-6Server`
echo "Identified VERSION ID ${RHEL7_CB_VID} as most current version of our RHEL7 Core Build"


###################################################################################################
#
# CV mariadb (puppet only since mariadb is part of RHEL7 and we don't use RHEL6 here) and according CCV
# 
###################################################################################################
hammer content-view create --name "cv-app-mariadb" --description "MariaDB Content View" --organization "$ORG"
# TODO figure out how to deal with puppetforge. If enabled we create product and repo during step2.
# but we don't want to sync the entire repo to local disk. We can not filter at the repo but only CV level.
# I've tried using the repo discovery and URLs directly to the module. None works. 
# As a temporary workaround we are downloading and pushing the modules directly until we made a decision.

# download the example42/mariadb puppet module
# TODO this will fail if customer has a proxy and not allows puppetforge
#wget -O /tmp/mariadb.tgz https://forgeapi.puppetlabs.com/v3/files/example42-mariadb-2.0.16.tar.gz
#hammer repository upload-content --organization $ORG --product $ORG --name "$ORG Puppet Repo" --path /tmp/mariadb.tgz
hammer content-view puppet-module add --content-view cv-app-mariadb --name mariadb --organization $ORG
hammer content-view  publish --name "cv-app-mariadb" --organization "$ORG" # --async # no async anymore, we need to wait until its published to created the CCV

# TODO decide if we really need the CCV or just it as a profile inside multi-tier roles (e.g. as part of ACME-Web CCV)
# create the CCV using the RHEL7 core build
#APP_CVID=`get_latest_version cv-app-mariadb`
#hammer content-view create --name "ccv-infra-mariadb" --composite --description "CCV for git Infra server" --organization $ORG --component-ids ${RHEL7_CB_VID},${APP_CVID}
#hammer content-view publish --name "ccv-infra-mariadb" --organization "$ORG"


###################################################################################################
#
# CV wordpress (contains EPEL7 + Filter)
# 
###################################################################################################
hammer content-view create --name "cv-app-wordpress" --description "Wordpress Content View" --organization "$ORG"
# TODO add puppet repo and modules as well
hammer content-view add-repository --organization "$ORG" --repository 'EPEL7-x86_64' --name "cv-app-wordpress" --product 'EPEL7'
hammer content-view filter create --type rpm --name 'wordpress-packages-only' --description 'Only include the wordpress rpm package' --inclusion=true --organization "$ORG" --repositories 'EPEL7-x86_64' --content-view "cv-app-wordpress"
hammer content-view filter rule create --name wordpress --organization "$ORG" --content-view "cv-app-wordpress" --content-view-filter 'wordpress-packages-only'


# add puppet modules from $ORG product repo to this CV
# hammer content-view puppet-module add --content-view cv-os-rhel-7Server --name <module_name> --organization $ORG

hammer content-view  publish --name "cv-app-wordpress" --organization "$ORG" # --async # no async anymore, we need to wait until its published to created the CCV

# TODO do we want to create an all-in-one CCV for all 3 parts or two separated ones; currently I've added only wordpress
# create the CCV using the RHEL7 core build out of newest version of all CVs inside
APP_CVID=`get_latest_version cv-app-wordpress`
hammer content-view create --name "ccv-biz-acmeweb" --composite --description "CCV for git Infra server" --organization $ORG --component-ids ${RHEL7_CB_VID},${APP_CVID}
hammer content-view publish --name "ccv-biz-acmeweb" --organization "$ORG"

###################################################################################################
#
# CV git (contains RHSCL repo + Filter) and according CCV
# 
###################################################################################################
hammer content-view create --name "cv-app-git" --description "The application specific content view for git." --organization "$ORG"
# add the RHSCL repo plus filter for git packages only
hammer content-view add-repository --organization "$ORG" --repository 'Red Hat Software Collections RPMs for Red Hat Enterprise Linux 7 Server x86_64 7Server' --name "cv-app-git" --product 'Red Hat Software Collections for RHEL Server'
hammer content-view filter create --type rpm --name 'git-packages-only' --description 'Only include the git rpm packages' --inclusion=true --organization "$ORG" --repositories 'Red Hat Software Collections RPMs for Red Hat Enterprise Linux 7 Server x86_64 7Server' --content-view "cv-app-wordpress"
hammer content-view filter rule create --name git19-git-all --organization "$ORG" --content-view "cv-app-git" --content-view-filter 'git-packages-only'

# add puppet modules from $ORG product repo to this CV
# TODO hammer content-view puppet-module add --content-view cv-app-git --name <module_name> --organization $ORG

hammer content-view  publish --name "cv-app-git" --organization "$ORG" # --async # no async anymore, we need to wait until its published to created the CCV

# create the CCV using the RHEL7 core build
APP_CVID=`get_latest_version cv-app-git`
hammer content-view create --name "ccv-infra-git" --composite --description "CCV for git Infra server" --organization $ORG --component-ids ${RHEL7_CB_VID},${APP_CVID}
hammer content-view publish --name "ccv-infra-git" --organization "$ORG" 
# TODO promote it to Dev

###################################################################################################
#
# CV Satellite 6 Capsule
# 
###################################################################################################
hammer content-view create --name "cv-app-sat6capsule" --description "Satellite 6 Capsule Content View" --organization "$ORG"
# TODO which repo do we need here? TODO add this repo to step2 as well
# hammer content-view add-repository --organization "$ORG" --repository 'TODO' --name "cv-app-sat6capsule" --product 'TODO'
# TODO RHSCL
hammer content-view  publish --name "cv-app-sat6capsule" --organization "$ORG" --async

# TODO do we need a CCV here as well?

###################################################################################################
#
# CV JBoss Enterprise Application Server 7
# 
###################################################################################################
hammer content-view create --name "cv-app-jbosseap7" --description "JBoss EAP 7 Content View" --organization "$ORG"
# TODO which repo do we need here? TODO add this repo to step2 as well
# hammer content-view add-repository --organization "$ORG" --repository 'TODO' --name "cv-app-sat6capsule" --product 'TODO'

# TODO add puppet modules from $ORG product repo to this CV
# hammer content-view puppet-module add --content-view cv-os-rhel-7Server --name <module_name> --organization $ORG

hammer content-view  publish --name "cv-app-jbosseap7" --organization "$ORG" --async

# TODO do we need a CCV here?

###################################################################################################
#
# CV docker-host (adds extras channel + filter)
# 
###################################################################################################
hammer content-view create --name "cv-app-docker" --description "Docker Host Content View" --organization "$ORG"
# TODO add puppet repo and modules as well
hammer content-view add-repository --organization "$ORG" --repository 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)' --name "cv-app-docker" --product 'Red Hat Enterprise Linux Server'
hammer content-view filter create --type rpm --name 'docker-package-only' --description 'Only include the docker rpm package' --inclusion=true --organization "$ORG" --repositories 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)' --content-view "cv-app-docker"
hammer content-view filter rule create --name docker --organization "$ORG" --content-view "cv-app-docker" --content-view-filter 'docker-package-only'
# TODO let's try the latest version (no version filter). If we figure out that it does not work add a filter for docker rpm version here or inside the puppet module

# add puppet modules from $ORG product repo to this CV
hammer content-view puppet-module add --content-view cv-app-docker --name profile_dockerhost --organization $ORG

# publish it and grep the task id since we need to wait until the task is finished before promoting it
hammer content-view  publish --name "cv-app-docker" --organization "$ORG"

APP_CVID=`get_latest_version cv-app-docker`
hammer content-view create --name "ccv-infra-docker" --composite --description "CCV for git docker compute resources" --organization $ORG --component-ids ${RHEL7_CB_VID},${APP_CVID}
hammer content-view publish --name "ccv-infra-docker" --organization "$ORG" 


###################################################################################################
###################################################################################################
#												  #
# COMPOSITE CONTENT VIEW PROMOTION								  #
#												  #
###################################################################################################
###################################################################################################
echo "Starting to promote our composite content views. This might take a while. Please be patient."

# get a list of all CCVs using hammer instead of hardcoded list
# TODO test and enable the section below
#for CVID in $(hammer content-view list --organization ACME | awk -F "|" '($4 ~/true/) {print $1}');
#do
#	# define the right lifecycle path based on our naming convention
#	if echo $a |grep -qe '^ccv-biz-acmeweb.*'; then 
#		echo "biz app"; 

#	elif echo $a | grep -qe '^ccv-infra-.*'; then 
#		echo "infra app";
#	else 
#		echo "unknown type";
#	fi

#	# get most current CV version id (thanks to mmccune)
#	VID=`hammer content-view version list --content-view-id $CVID | awk -F'|' '{print $1}' | sort -n  | tac | head -n 1`
#	# promote it to dev and return task id
#	TASKID=$(hammer content-view version promote --content-view-id $CVID  --organization "$ORG" --async --to-lifecycle-environment DEV --id $VID)
#	hammer task progress --id $TASKID

#done


