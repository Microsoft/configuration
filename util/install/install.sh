########################
# INSTALL.SH
########################

#!/bin/bash

# Set the OPENEDX_RELEASE variable:
export OPENEDX_RELEASE=oxa/dev.haw_migration_2
export EDX_OPENEDX_RELEASE=open-release/hawthorn.master

# argument defaults
VAULT_NAME=""
CRT_SECRET_NAME=""
KEY_SECRET_NAME=""
CRT_FILE=""
KEY_FILE=""

# Oxa Tools
# Settings for the OXA-Tools public repository 
OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME="Microsoft"
OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME="oxa-tools"
OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH="oxa/master.fic"

display_usage()
{
    echo "Usage: $0 --vault-name {Vault name} --crt-secret-key {CRT secret name} --key-secret-name {KEY secret name} --crt-filename {CRT filename} --key-filename {KEY filename}"
    exit 1
}

parse_args() 
{
    while [[ "$#" -gt 0 ]] ; do
        arg_value="${2}"

        shift_once=0

        if [[ "${arg_value}" =~ "--" ]] ; then
            arg_value=""
            shift_once=1
        fi

        # Log input parameters to facilitate troubleshooting

        echo "Option '${1}' set with value '"${arg_value}"'"

        case "$1" in
          --vault-name)
            VAULT_NAME="${arg_value}"
            ;;
          --crt-secret-name)
            CRT_SECRET_NAME="${arg_value}"
            ;;
          --key-secret-name)
            KEY_SECRET_NAME="${arg_value}"
            ;;
          --crt-filename)
            CRT_FILE="${arg_value}"
            ;;
          --key-filename)
            KEY_FILE="${arg_value}"
            ;;
          *)
            # Unknown option encountered
            echo "Option '${BOLD}$1${NORM} ${arg_value}' not allowed."
            display_usage
            ;;
        esac

        shift # past argument or value


        if [[ $shift_once -eq 0 ]] ; then
            shift # past argument or value
        fi

    done
}

source_utilities()
{
    # get current dir
    CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    # source utilities for logging and other base functions
    cd $CURRENT_PATH/..
    UTILITIES_PATH=templates/stamp/utilities.sh

    # check if the utilities file exists. If not, download from the public repository
    if [[ ! -e $UTILITIES_PATH ]] ; then
        cd $CURRENT_PATH
        fileName=`basename $UTILITIES_PATH`
        wget -q https://raw.githubusercontent.com/${OXA_TOOLS_PUBLIC_GITHUB_ACCOUNTNAME}/${OXA_TOOLS_PUBLIC_GITHUB_PROJECTNAME}/${OXA_TOOLS_PUBLIC_GITHUB_PROJECTBRANCH}/${UTILITIES_PATH} -O $fileName
        UTILITIES_PATH=$fileName
    fi

    # source the utilities now
    source $UTILITIES_PATH
}

fetch_keyvault_cert_and_key()
{
    # Login via MSI
    az login --identity

    if [[ $? -eq 0 ]]; then
        # Fetch cert from KeyVault
        az keyvault secret download --vault-name $VAULT_NAME --name $CRT_SECRET_NAME --file /etc/ssl/certs/$CRT_FILE --encoding base64 &&

        # Fetch key from KeyVault
        az keyvault secret download --vault-name $VAULT_NAME --name $KEY_SECRET_NAME --file /etc/ssl/private/$KEY_FILE --encoding base64

        result=$?

        if [[ $result -ne 0 ]]; then
            log "Unable to fetch cert/key from KeyVault" 1
        fi

        az logout

        if [[ $result -ne 0 ]]; then
            exit 1
        fi
    else
        exit_on_error "Unable to login to Azure via MSI"
    fi
}

###############################################
# START CORE EXECUTION
###############################################

# pass existing command line arguments
parse_args "$@"

# source utilities for logging and other base functions
source_utilities

# Install Azure CLI 2.0 needed for KeyVault access 
install-azure-cli-2

# Install cert and key
fetch_keyvault_cert_and_key

# Bootstrap the Ansible installation
wget https://raw.githubusercontent.com/microsoft/edx-configuration/$OPENEDX_RELEASE/util/install/ansible-bootstrap.sh -O - | sudo bash

# Install Open edX. For Ginkgo and older, this will be a 404, and you need to use sandbox.sh instead of native.sh
wget https://raw.githubusercontent.com/microsoft/edx-configuration/$OPENEDX_RELEASE/util/install/native.sh -O - | bash
