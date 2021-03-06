#! /bin/bash

#
# this script automatically does the setup documented in the reference architecture "10 steps to create a SOE"
# 

# TODO short desc and outcome of this step

# latest version in github: https://github.com/dirkherrmann/soe-reference-architecture

DIR="$PWD"
source "${DIR}/common.sh"


###################################################################################################
#
# EXAMPLE PUPPET MODULES PUSH 
#
###################################################################################################
# we need to push our pre-built puppet modules into git and enable the repo sync
# TODO double-check if this is the right chapter for this task

# TODO create a local git repo and make it available as sync repo
# in the meantime let's push the modules inside our example module dir directly
# push the example puppet module into our $ORG Puppet Repo
for module in $(ls ./puppet/*/*gz)
do
	echo "Pushing example module $module into our puppet repo"
	hammer -v repository upload-content --organization $ORG --product ACME --name "ACME Puppet Repo" --path $module
done

# the following lines are the bash work-around for pulp-puppet-module-builder
#for file in $@
#do
#    echo $file,`sha256sum $file | awk '{ print $1 }'`,`stat -c '%s' $file`
#done

###################################################################################################
#
# RHEL 6 Core Build Content View - TODO NOT TESTED YET!
#
###################################################################################################
if [ "$RHEL6_ENABLED" -eq 1 ]
then
	hammer content-view create --name "cv-os-rhel-6Server" --description "RHEL Server 6 Core Build Content View" --organization "$ORG"
	# software repositories
	hammer content-view add-repository --organization "$ORG" --name "cv-os-rhel-6Server" --repository 'Red Hat Enterprise Linux 6 Server Kickstart x86_64 6Server' --product 'Red Hat Enterprise Linux Server'
	hammer content-view add-repository --organization "$ORG" --name "cv-os-rhel-6Server" --repository 'Red Hat Enterprise Linux 6 Server RPMs x86_64 6Server' --product 'Red Hat Enterprise Linux Server'
	# TODO has to be substituted by 6.1 sat-tools channel which is not there yet
	hammer content-view add-repository --organization "$ORG" --name "cv-os-rhel-6Server" --repository 'Red Hat Enterprise Linux 6 Server - RH Common RPMs x86_64 6Server' --product 'Red Hat Enterprise Linux Server'

	hammer content-view add-repository --organization "$ORG" --name "cv-os-rhel-6Server" --repository 'Zabbix-RHEL6-x86_64' --product 'Zabbix-Monitoring'
	hammer content-view add-repository --organization "$ORG" --name "cv-os-rhel-6Server" --repository 'Bareos-RHEL6-x86_64' --product 'Bareos-Backup-RHEL6'

	# puppet modules which are part of core build 
	# Note: since all modules are RHEL major release independent we're adding the same modules as for RHEL 7 Core Build
	hammer content-view puppet-module add --content-view cv-os-rhel-6Server --name motd --organization $ORG
	hammer content-view puppet-module add --content-view cv-os-rhel-6Server --name adminuser --organization $ORG
	hammer content-view puppet-module add --content-view cv-os-rhel-6Server --name language --organization $ORG
	hammer content-view puppet-module add --content-view cv-os-rhel-6Server --name ntp --organization $ORG
	hammer content-view puppet-module add --content-view cv-os-rhel-6Server --name timezone --organization $ORG
	hammer content-view puppet-module add --content-view cv-os-rhel-6Server --name loghost --organization $ORG
	hammer content-view puppet-module add --content-view cv-os-rhel-6Server --name zabbix --organization $ORG

	# CV publish without --async option to ensure that the CV is published before we create CCVs in the next step
	hammer content-view  publish --name "cv-os-rhel-6Server" --organization "$ORG" #--async	
fi
###################################################################################################
#
# RHEL7 Core Build Content View
#
###################################################################################################
hammer content-view create --name "cv-os-rhel-7Server" --description "RHEL Server 7 Core Build Content View" --organization "$ORG"
# software repositories
hammer content-view add-repository --organization "$ORG" --name "cv-os-rhel-7Server" --repository 'Red Hat Enterprise Linux 7 Server Kickstart x86_64 7Server' --product 'Red Hat Enterprise Linux Server'
hammer content-view add-repository --organization "$ORG" --name "cv-os-rhel-7Server" --repository 'Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server' --product 'Red Hat Enterprise Linux Server'
# TODO has to be substituted by 6.1 sat-tools channel which is not there yet
hammer content-view add-repository --organization "$ORG" --name "cv-os-rhel-7Server" --repository 'Red Hat Enterprise Linux 7 Server - RH Common RPMs x86_64 7Server' --product 'Red Hat Enterprise Linux Server'
# TODO check if still needed if we use Zabbix now. Changed from APP to CoreBuild instead.
hammer content-view add-repository --organization "$ORG" --name "cv-os-rhel-7Server" --repository 'Zabbix-RHEL7-x86_64' --product 'Zabbix-Monitoring'
hammer content-view add-repository --organization "$ORG" --name "cv-os-rhel-7Server" --repository 'Bareos-RHEL7-x86_64' --product 'Bareos-Backup-RHEL7'

# we are creating an initial version just containing RHEL 7.0 bits based on a date filter between RHEL 7.0 GA and before RHEL 7.1 GA
# TODO currently we can't update or delete the filter without UI since option list does not work. commenting the filter out until it works
#hammer content-view filter create --type erratum --name 'rhel-7.0-only' --description 'Only include RHEL 7.0 bits' --inclusion=true --organization "$ORG" --repositories 'Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server' --content-view "cv-os-rhel-7Server"
#hammer content-view filter rule create  --organization "$ORG" --content-view "cv-os-rhel-7Server" --content-view-filter 'rhel-7.0-only' --start-date 2014-06-09 --end-date 2015-03-01 --types enhancement,bugfix,security


# add all puppet modules which are part of core build
hammer content-view puppet-module add --content-view cv-os-rhel-7Server --name motd --organization $ORG
hammer content-view puppet-module add --content-view cv-os-rhel-7Server --name adminuser --organization $ORG
hammer content-view puppet-module add --content-view cv-os-rhel-7Server --name language --organization $ORG
hammer content-view puppet-module add --content-view cv-os-rhel-7Server --name ntp --organization $ORG
hammer content-view puppet-module add --content-view cv-os-rhel-7Server --name timezone --organization $ORG
hammer content-view puppet-module add --content-view cv-os-rhel-7Server --name loghost --organization $ORG
hammer content-view puppet-module add --content-view cv-os-rhel-7Server --name zabbix --organization $ORG

# CV publish without --async option to ensure that the CV is published before we create CCVs in the next step
hammer content-view  publish --name "cv-os-rhel-7Server" --organization "$ORG" #--async

# TODO now create a new version of cv including all erratas until today (removing the date filter created earlier)

