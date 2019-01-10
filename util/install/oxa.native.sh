#!/bin/bash
##
## This script is a derivative of the edx native.sh. 
## It has additional configuration options specific to installing Open edX on Azure.
##
## Installs the pre-requisites for running Open edX on a single Ubuntu 16.04
## instance.  This script is provided as a convenience and any of these
## steps could be executed manually.
##
## Note that this script requires that you have the ability to run
## commands as root via sudo.  Caveat Emptor!
##

# variables for accessing the secret store (keyvault)
vault_name=""
crt_secret_name="OxaToolsConfigxxxcertyyycrt"
key_secret_name="OxaToolsConfigxxxcertyyykey"
crt_file="cert.crt"
key_file="cert.key"

# variables for the playbook to execute
target_playbook=""
playbook_configs=""

##
## Fetch the SSL certificate & key for NGINX
##
fetch_ssl_certificate()
{
    # Login via MSI
    az login --identity

    if [[ $? -eq 0 ]]; then
        # Fetch cert from KeyVault
        az keyvault secret download --vault-name $vault_name --name $crt_secret_name --file /etc/ssl/certs/$crt_file --encoding base64

        result=$?
        if [[ $result -ne 0 ]]; then
            log "Unable to fetch SSL cert from KeyVault" 1
            exit 1
        fi


        # Fetch key from KeyVault
        az keyvault secret download --vault-name $vault_name --name $key_secret_name --file /etc/ssl/private/$key_file --encoding base64
        
        result=$?
        if [[ $result -ne 0 ]]; then
            log "Unable to fetch SSL key from KeyVault" 1
            exit 1
        fi

        az logout
    else
        exit_on_error "Unable to login to Azure via MSI"
    fi
}

##
## Source collection of support functions
##
source_utilities()
{
    # at this point in the installation, the utilities file should be already present
    # access it from its known location
    utilities_path="/oxa/oxa-tools/templates/stamp/utilities.sh"
    
    # check if the utilities file exists. If not, bail out.
    if [[ ! -e $utilities_path ]]; 
    then  
        echo "Utilities not present" 1
        exit 3
    fi

    # source the utilities now
    source $utilities_path
}

function finish {
    echo "Installation finished at $(date '+%Y-%m-%d %H:%M:%S')"
}

###############################################
# START CORE EXECUTION
###############################################

if [[ ! $OPENEDX_RELEASE ]]; then
    echo "You must define OPENEDX_RELEASE"
    exit 2
fi

if [[ `lsb_release -rs` != "16.04" ]]; then
    echo "This script is only known to work on Ubuntu 16.04, exiting..."
    exit 2
fi

if [[ ! $OXA_TARGET_PLAYBOOK ]]; 
then
    echo "You must specify the target playbook to execute: --playbook x.yml"
    exit 2
else
    target_playbook=$OXA_TARGET_PLAYBOOK
fi

if [[ ! $OXA_PLAYBOOK_CONFIGS ]] || [[ ! -f $OXA_PLAYBOOK_CONFIGS ]]; then
    echo "You must specify the path to the config file to use: --config /a.yml"
    exit 2
else
     playbook_configs=$OXA_PLAYBOOK_CONFIGS
fi

if [[ ! $OXA_VAULT_NAME ]]; then
    echo "You must specify the vault and certificate secret name & key"
    exit 2
else
    vault_name=$OXA_VAULT_NAME
fi

##
## Log what's happening
##

mkdir -p logs
log_file=logs/install-$(date +%Y%m%d-%H%M%S).log
exec > >(tee $log_file) 2>&1
echo "Capturing output to $log_file"
echo "Installation started at $(date '+%Y-%m-%d %H:%M:%S')"

trap finish EXIT

echo "Installing release '$OPENEDX_RELEASE'"

##
## Set ppa repository source for gcc/g++ 4.8 in order to install insights properly
##
sudo apt-get install -y python-software-properties
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test

##
## Update and Upgrade apt packages
##
sudo apt-get update -y
sudo apt-get upgrade -y

##
## Install system pre-requisites
##
sudo apt-get install -y build-essential software-properties-common curl git-core libxml2-dev libxslt1-dev python-pip libmysqlclient-dev python-apt python-dev libxmlsec1-dev libfreetype6-dev swig gcc g++
sudo pip install --upgrade pip==9.0.3
sudo pip install --upgrade setuptools==39.0.1
sudo -H pip install --upgrade virtualenv==15.2.0

##
## Overridable version variables in the playbooks. Each can be overridden
## individually, or with $OPENEDX_RELEASE.
##
VERSION_VARS=(
    edx_platform_version
    configuration_version
    THEMES_VERSION
)

EDX_VERSION_VARS=(
    certs_version
    forum_version
    xqueue_version
    configuration_version
    demo_version
    NOTIFIER_VERSION
    INSIGHTS_VERSION
    ANALYTICS_API_VERSION
    ECOMMERCE_VERSION
    ECOMMERCE_WORKER_VERSION
    DISCOVERY_VERSION
)

for var in ${VERSION_VARS[@]}; do
    # Each variable can be overridden by a similarly-named environment variable,
    # or OPENEDX_RELEASE, if provided.
    ENV_VAR=$(echo $var | tr '[:lower:]' '[:upper:]')
    eval override=\${$ENV_VAR-\$OPENEDX_RELEASE}
    if [ -n "$override" ]; then
        EXTRA_VARS="-e $var=$override $EXTRA_VARS"
    fi
done

for var in ${EDX_VERSION_VARS[@]}; do
    # Each variable can be overridden by a similarly-named environment variable,
    # or EDX_OPENEDX_RELEASE, if provided.
    ENV_VAR=$(echo $var | tr '[:lower:]' '[:upper:]')
    eval override=\${$ENV_VAR-\$EDX_OPENEDX_RELEASE}
    if [ -n "$override" ]; then
        EXTRA_VARS="-e $var=$override $EXTRA_VARS"
    fi
done

# configuration file with setting overrides generated by the configuration system.
EXTRA_VARS="-e@${playbook_configs} $EXTRA_VARS"

# Add support for migration mode
if [[ $RUN_MIGRATION = true ]]; then
    EXTRA_VARS="--tags migrate $EXTRA_VARS"
fi

CONFIGURATION_VERSION=${CONFIGURATION_VERSION-$OPENEDX_RELEASE}

##
## Clone the configuration repository and run Ansible
##
cd /var/tmp
git clone https://github.com/Microsoft/edx-configuration configuration
cd configuration
git checkout $CONFIGURATION_VERSION
git pull

##
## Install the ansible requirements
##
cd /var/tmp/configuration
sudo -H pip install -r requirements.txt

##
## Run the specified playbook in the configuration/playbooks directory
##
cd /var/tmp/configuration/playbooks && sudo -E ansible-playbook -c local ./"${target_playbook}" -i "localhost," $EXTRA_VARS "$@"
ansible_status=$?

if [[ $ansible_status -ne 0 ]]; then
    echo " "
    echo "========================================"
    echo "Ansible failed!"
    echo "----------------------------------------"
    echo "If you need help, see https://open.edx.org/getting-help ."
    echo "When asking for help, please provide as much information as you can."
    echo "These might be helpful:"
    echo "    Your log file is at $log_file"
    echo "    Your environment:"
    env | egrep -i 'version|release' | sed -e 's/^/        /'
    echo "========================================"
    exit 3
fi
