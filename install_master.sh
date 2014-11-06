set -e

THIS_DIR=`pwd`
DATA_PATH=$THIS_DIR/data
PUPPET_MODULE_PATH="--modulepath=modules:system-config/modules:/etc/puppet/modules"

# Pulling in variables from data repository
. $DATA_PATH/vars.sh

PUBLISH_HOST=${PUBLISH_HOST:-localhost}

# Create a self-signed SSL certificate for use in Apache
APACHE_SSL_ROOT_DIR=$THIS_DIR/tmp/apache/ssl
if [[ ! -e $APACHE_SSL_ROOT_DIR/new.ssl.csr ]]; then
    echo "Creating self-signed SSL certificate for Apache"
    mkdir -p $APACHE_SSL_ROOT_DIR
    cd $APACHE_SSL_ROOT_DIR
    echo '
[ req ]
default_bits            = 2048
default_keyfile         = new.key.pem
default_md              = default
prompt                  = no
distinguished_name      = distinguished_name

[ distinguished_name ]
countryName             = US
stateOrProvinceName     = CA
localityName            = Sunnyvale
organizationName        = OpenStack
organizationalUnitName  = OpenStack
commonName              = localhost
emailAddress            = openstack@openstack.org
' > ssl_req.conf
    # Create the certificate signing request
    openssl req -new -config ssl_req.conf -nodes > new.ssl.csr
    # Generate the certificate from the CSR
    openssl rsa -in new.key.pem -out new.cert.key
    openssl x509 -in new.ssl.csr -out new.cert.cert -req -signkey new.cert.key -days 3650
    cd $THIS_DIR
fi
APACHE_SSL_CERT_FILE=`cat $APACHE_SSL_ROOT_DIR/new.cert.cert`
APACHE_SSL_KEY_FILE=`cat $APACHE_SSL_ROOT_DIR/new.cert.key`

CLASS_ARGS="jenkins_ssh_public_key => '$JENKINS_SSH_PUBLIC_KEY_CONTENTS', jenkins_ssh_private_key => '$JENKINS_SSH_PRIVATE_KEY_CONTENTS', "
CLASS_ARGS="$CLASS_ARGS ssl_cert_file_contents => '$APACHE_SSL_CERT_FILE', ssl_key_file_contents => '$APACHE_SSL_KEY_FILE', "
CLASS_ARGS="$CLASS_ARGS upstream_gerrit_user => '$UPSTREAM_GERRIT_USER', "
CLASS_ARGS="$CLASS_ARGS upstream_gerrit_ssh_private_key => '$UPSTREAM_GERRIT_SSH_PRIVATE_KEY_CONTENTS', "
CLASS_ARGS="$CLASS_ARGS upstream_gerrit_host_pub_key => '$UPSTREAM_GERRIT_HOST_PUB_KEY', "
CLASS_ARGS="$CLASS_ARGS git_email => '$GIT_EMAIL', git_name => '$GIT_NAME', "
CLASS_ARGS="$CLASS_ARGS publish_host => '$PUBLISH_HOST', "
CLASS_ARGS="$CLASS_ARGS data_repo_dir => '$DATA_PATH', "
CLASS_ARGS="$CLASS_ARGS url_pattern => '$URL_PATTERN', "

# Doing this here because ran into one problem after another trying
# to do this in Puppet... which won't let me execute Ruby code in
# a manifest and doesn't allow you to "merge" the contents of two
# directory sources in the file resource. :(
sudo mkdir -p /etc/jenkins_jobs/config
sudo cp -r $DATA_PATH/etc/jenkins_jobs/config/* /etc/jenkins_jobs/config/

if [[ ! -e project-config ]]; then
	git clone https://github.com/openstack-infra/project-config
	mkdir -p modules/project/files
	cp -r project-config/* modules/project/files/
fi

sudo puppet apply --verbose $PUPPET_MODULE_PATH -e "class {'third_party_ci::master': $CLASS_ARGS }"
