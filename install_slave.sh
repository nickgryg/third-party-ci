set -e

THIS_DIR=`pwd`
DATA_PATH=$THIS_DIR/data
PUPPET_MODULE_PATH="--modulepath=$OSEXT_PATH/modules:system-config/modules:/root/config/modules:/etc/puppet/modules"

# Pulling in variables from data repository
. $DATA_PATH/vars.sh

sed -i 's|secret|secretmysql|' system-config/modules/devstack_host/manifests/init.pp
sudo sed '|servers_real|@servers_real|' /etc/puppet/modules/ntp/templates/ntp.conf.debian.erb

CLASS_ARGS="ssh_key => '$JENKINS_SSH_PUBLIC_KEY_CONTENTS', "

sudo puppet apply --verbose $PUPPET_MODULE_PATH -e "class {'os_ext_testing::devstack_slave': $CLASS_ARGS }"

#if [[ ! -e /opt/git ]]; then
#    sudo mkdir -p /opt/git
#    sudo -i python /opt/nodepool-scripts/cache_git_repos.py
#    sudo /opt/nodepool-scripts/prepare_devstack.sh
#fi
