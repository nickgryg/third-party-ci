set -e

THIS_DIR=`pwd`
DATA_PATH=$THIS_DIR/data
PUPPET_MODULE_PATH="--modulepath=modules:system-config/modules:/etc/puppet/modules"

# Pulling in variables from data repository
. $DATA_PATH/vars.sh
JENKINS_SSH_PRIVATE_KEY_CONTENTS=`sudo cat $DATA_PATH/$JENKINS_SSH_KEY_PATH`
JENKINS_SSH_PUBLIC_KEY_CONTENTS=`sudo cat $DATA_PATH/$JENKINS_SSH_KEY_PATH.pub`

sed -i 's|secret|secretmysql|' system-config/modules/devstack_host/manifests/init.pp
#sudo sed -i 's|servers_real|@servers_real|' /etc/puppet/modules/ntp/templates/ntp.conf.debian.erb

CLASS_ARGS="ssh_key => '$JENKINS_SSH_PUBLIC_KEY_CONTENTS', "

sudo puppet apply --verbose $PUPPET_MODULE_PATH -e "class {'openstack_project::slave': $CLASS_ARGS }"

if [[ ! -e /opt/nodepool-scripts ]]; then
    sudo mkdir -p /opt/git
    git clone https://github.com/openstack-infra/project-config 
    sudo mkdir -p /opt/nodepool-scripts
    sudo cp -r project-config/nodepool/scripts/* /opt/nodepool-scripts/ 
    sudo -i python /opt/nodepool-scripts/cache_git_repos.py
    sudo /bin/bash -ex /opt/nodepool-scripts/prepare_devstack.sh
fi
