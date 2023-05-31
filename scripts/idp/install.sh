#!/bin/bash

# function to check if all environment variables are set correctly
function check_env() {
    # check if all variables are set
    for v in "$@"; do
        var="${v%=*}"
        default_value="${v#*=}"

        if [ -z "${!var}" ]; then
            echo "ERROR: ${var} has not been set"
            exit 1
        else
            echo "${var} = \"${!var}\""
        fi
    done

    # check if user would like to continue with all values
    read -p "Would you like to continue with the above values? [y/N]: " -n 1 -r
    echo
    if [[ ! ${REPLY} =~ ^[Yy]$ ]]
    then
        exit 1
    fi
}

# function to get input from user
function get_user_input() {
    for v in "$@"; do
        var="${v%=*}"
        default_value="${v#*=}"

        if [ -z "${!var}" ]; then
            while [ -z "${!var}" ]; do
                read -p "Enter a value for ${var} [$(eval echo "${default_value}")]: " user_value
                # if user value is given, set the variable to the user value
                if [ "${user_value}" ]; then
                    export "${var}"=$(eval echo "${user_value}")
                # otherwise, if default value is given, set the variable to the default value
                elif [ "${default_value}" ]; then
                    export "${var}"=$(eval echo "${default_value}")
                fi
            done
        fi
    done
}

# function to set default value if not set
function set_default() {
    # first var is the ENV variable, second var is the default value
    if [ -z "${!1}" ]; then
        echo "\$$1 is not set, setting it to '$2'"
        export $1=$2
    fi
}

# function to check if local file exists
function check_local_file_exists() {
    local found_file=""

    # look for files and stop when found
    for file in "$@"; do
        if [ -f "${file}" ]; then
            found_file="${file}"
            break
        fi
    done

    # check if a single file is found
    if [ -n "${found_file}" ]; then
        echo "Required file is available (${found_file})"
    else
        echo "ERROR: None of the specified files were found ($*)"
        exit 1
    fi

    return 0
}

# function to download file when ready
function download_when_ready() {
    # first var is the file name, second var is the file url, third var is the file description
    echo "Waiting for the $3 file to be ready ($2)"

    sleep 30

    for i in {1..5}; do
        if curl -s -m 10 -o /dev/null -w "%{http_code}" "$2" | grep -q "200"; then
            curl -s -o "$1" "$2"
            break

        elif curl --insecure -s -m 10 -o /dev/null -w "%{http_code}" "$2" | grep -q "200"; then
            curl --insecure -s -o "$1" "$2"
            break

        else
            sleep 10
        fi
    done

    check_local_file_exists $1
}

# function to add helm repo if haven't and update
function add_helm_repo() {
    # first var is the repo name, second var is the repo url
    if ! helm repo list | grep -q "$1"; then
        helm repo add "$1" "$2"
    fi

    helm repo update "$1"
}

# function to print help message
function print_help() {
    echo "Usage: $0 [options]"; echo
    echo "OPTIONS:"
    echo "  -c, --chart <chart>          Specify a custom installation chart"
    echo "  -d, --dry-run                Perform a dry run of helm install/upgrade"
    echo "  -h, --help                   Print help message"
}

# ================= DO NOT EDIT BEYOND THIS LINE =================


# get optional argument
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--chart)
            if [ -z "$2" ]; then
                echo "ERROR: Please specify an installation chart"
                exit 1
            fi
            CHART="$2"
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=1
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "ERROR: Invalid argument ($1)"
            exit 1
            ;;
    esac
    shift
done

# get backend authenticator
get_user_input "BACKEND_AUTH=vikings"
echo "Backend authenticator for the IdP has been set (${BACKEND_AUTH})"

# set required variables
required_variables=(
    "LONG_ORG_NAME="
    "SHORT_ORG_NAME="
    "ORG_WEBSITE="
    "ORG_SUPPORT_EMAIL="
    "ORG_DOMAIN="
    "ORG_SCOPE=\${ORG_DOMAIN}"
    "SHIBBOLETH_SUBDOMAIN=idp.\${ORG_DOMAIN}"
)

if [ "${BACKEND_AUTH}" == "azure_ad" ] || [ "${BACKEND_AUTH}" == "google" ]; then
    required_variables+=(
        "STAFF_EMAIL_DOMAIN=\${ORG_DOMAIN}"
        "STUDENT_EMAIL_DOMAIN=-"
    )
else
    required_variables+=(
        "DB_HOSTNAME="
        "DB_NAME="
        "DB_USER="
        "DB_PASSWORD="
    )
fi

# get required variables
get_user_input "${required_variables[@]}"

# check if all environment variables are set
check_env "${required_variables[@]}"

# set ENV variables default values if not set
set_default VALUES_FILE "values.yaml" \
&& set_default FED_SIGNER_FILE "fed_signer.crt" \
&& set_default AZURE_METADATA_FILE "azure.xml" \
&& set_default GOOGLE_METADATA_FILE "GoogleIDPMetadata.xml" \
&& set_default SHIB_METADATA_FILE "${SHORT_ORG_NAME}-shib-metadata.xml" \
&& set_default SHIB_METADATA_URL "https://${SHIBBOLETH_SUBDOMAIN}/idp/shibboleth"

# check for required files
check_local_file_exists ${VALUES_FILE} \
&& check_local_file_exists ${FED_SIGNER_FILE}

if [ "${BACKEND_AUTH}" == "azure_ad" ]; then
    check_local_file_exists "${AZURE_METADATA_FILE}"
    IDP_METADATA_FILE="${AZURE_METADATA_FILE}"
elif [ "${BACKEND_AUTH}" == "google" ]; then
    check_local_file_exists "${GOOGLE_METADATA_FILE}"
    IDP_METADATA_FILE="${GOOGLE_METADATA_FILE}"
fi

# set installation chart
if [ -z "${CHART}" ]; then
    echo "Adding/updating helm repo (ifirexman)"
    # add sifulan helm repo if haven't and update
    add_helm_repo "ifirexman" "https://raw.githubusercontent.com/sifulan-access-federation/ifirexman-charts/master"
    # set chart to default
    CHART="ifirexman/ifirexman-shibboleth-idp"
fi
echo "Helm installation chart has been set (${CHART})"

# check if the following files exist, if any of them is missing, create the files:
# - idp-signing.crt
# - idp-signing.key
# - idp-encryption.crt
# - idp-encryption.key
# - idp-backchannel.crt
# - idp-backchannel.p12
# - sealer.jks
# - sealer.kver
# - secrets.properties
for file in idp-signing.crt idp-signing.key idp-encryption.crt idp-encryption.key idp-backchannel.crt idp-backchannel.p12 sealer.jks sealer.kver secrets.properties; do
    if [ ! -f "${file}" ]; then
        echo "WARNING: Required Shibboleth credential is missing (${file})"

        # determine container runtime
        if [ -x "$(command -v docker)" ]; then
            CONTAINER_RUNTIME="docker"
        elif [ -x "$(command -v podman)" ]; then
            CONTAINER_RUNTIME="podman"
        elif [ -x "$(command -v nerdctl)" ]; then
            CONTAINER_RUNTIME="nerdctl"
        else
            echo "ERROR: You must have a supported container runtime installed"
            exit 1
        fi

        # create shibboleth certificates
        echo "Creating shibboleth certificates"
        ${CONTAINER_RUNTIME} run -it --rm -v ${PWD}:/opt/shibboleth-idp/credentials ghcr.io/sifulan-access-federation/shibboleth-idp-base:4.2.1 /scripts/install.sh ${SHIBBOLETH_SUBDOMAIN} ${ORG_DOMAIN}

        # change ownership of the certificates
        echo "Changing ownership of the certificates to the user (${USER})"
        sudo chown -R ${USER}: .

        # set random salt for persistent ID
        echo "Setting random salt for persistent ID (secrets.properties)"
        salt=`openssl rand -hex 32` && sed "s/\#idp.persistentId.salt = changethistosomethingrandom/idp.persistentId.salt = `echo ${salt}`/" secrets.properties > secrets.properties.tmp && mv secrets.properties.tmp secrets.properties

        break
    else
        echo "Required Shibboleth credential is found (${file})"
    fi
done

# extract the entity ID from the idp metadata file if applicable
if [ -f "${IDP_METADATA_FILE}" ]; then
    echo "Extracting the entity ID from the idp metadata file (${IDP_METADATA_FILE})"
    ENTITY_ID=`xmllint --pretty 1 ${IDP_METADATA_FILE} | grep entityID | sed 's/.*entityID="\([^"]*\)".*/\1/'`
fi

# determine if chart is to be installed or upgraded
echo "Checking if release exists in the namespace (${SHORT_ORG_NAME})"
if helm ls -n ${SHORT_ORG_NAME} | grep "${SHORT_ORG_NAME}-idp" > /dev/null; then
    CHART_OPERATION="upgrade"
else
    CHART_OPERATION="install"
fi

# prepare helm command
echo "Preparing helm command (${CHART_OPERATION})"
helm_command="helm ${CHART_OPERATION} ${SHORT_ORG_NAME}-idp ${CHART} \
--namespace ${SHORT_ORG_NAME} \
--create-namespace \
--values ${VALUES_FILE} \
--set idp.domain=\"${SHIBBOLETH_SUBDOMAIN}\" \
--set idp.scope=\"${ORG_SCOPE}\" \
--set idp.fullname=\"${LONG_ORG_NAME}\" \
--set idp.shortname=\"${SHORT_ORG_NAME}\" \
--set idp.website=\"${ORG_WEBSITE}\" \
--set idp.support_email=\"${ORG_SUPPORT_EMAIL}\" \
--set idp.sealer_jks=\"$(base64 sealer.jks)\" \
--set-file idp.signing_cert=idp-signing.crt \
--set-file idp.signing_key=idp-signing.key \
--set-file idp.encryption_cert=idp-encryption.crt \
--set-file idp.encryption_key=idp-encryption.key \
--set-file idp.sealer_kver=sealer.kver \
--set-file idp.secrets_properties=secrets.properties \
--set idp.${BACKEND_AUTH}.enabled=true \
--set-file federation.signer_cert=${FED_SIGNER_FILE}"

# configurations specific to azure_ad and google backend authenticators
if [ "${BACKEND_AUTH}" == "azure_ad" ] || [ "${BACKEND_AUTH}" == "google" ]; then
    helm_command="${helm_command} \
--set idp.${BACKEND_AUTH}.entity_id=\"${ENTITY_ID}\" \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.attribute=\"mail\" \
--set-file idp.${BACKEND_AUTH}.metadata=${IDP_METADATA_FILE}"

    # sharing staff and student email domain
    if [ "${STAFF_EMAIL_DOMAIN}" == "${STUDENT_EMAIL_DOMAIN}" ]; then
        helm_command="${helm_command} \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.valueMap\[0\].attributeReturn=\"member\" \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.valueMap\[0\].attributeValues\[0\]=\"@${STAFF_EMAIL_DOMAIN}\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.attribute=\"eduPersonAffiliation\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[0\].attributeReturn=\"urn:mace:${ORG_DOMAIN}:member\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[0\].attributeValues\[0\]=\"member\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[1\].attributeReturn=\"urn:mace:dir:entitlement:common-lib-terms\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[1\].attributeValues\[0\]=\"member\""
    else
        # separate student and staff email domains
        if [ "${STUDENT_EMAIL_DOMAIN}" != "-" ]; then
            helm_command="${helm_command} \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.valueMap\[0\].attributeReturn=\"staff\" \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.valueMap\[0\].attributeValues\[0\]=\"@${STAFF_EMAIL_DOMAIN}\" \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.valueMap\[1\].attributeReturn=\"student\" \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.valueMap\[1\].attributeValues\[0\]=\"@${STUDENT_EMAIL_DOMAIN}\" \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.valueMap\[2\].attributeReturn=\"member\" \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.valueMap\[2\].attributeValues\[0\]=\"@${STAFF_EMAIL_DOMAIN}\" \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.valueMap\[2\].attributeValues\[1\]=\"@${STUDENT_EMAIL_DOMAIN}\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.attribute=\"eduPersonAffiliation\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[0\].attributeReturn=\"urn:mace:${ORG_DOMAIN}:staff\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[0\].attributeValues\[0\]=\"staff\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[1\].attributeReturn=\"urn:mace:${ORG_DOMAIN}:student\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[1\].attributeValues\[0\]=\"student\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[2\].attributeReturn=\"urn:mace:${ORG_DOMAIN}:member\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[2\].attributeValues\[0\]=\"member\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[3\].attributeReturn=\"urn:mace:dir:entitlement:common-lib-terms\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[3\].attributeValues\[0\]=\"member\""
        # single staff email domain with no student email domain
        else
            helm_command="${helm_command} \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.valueMap\[0\].attributeReturn=\"staff\" \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.valueMap\[0\].attributeValues\[0\]=\"@${STAFF_EMAIL_DOMAIN}\" \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.valueMap\[1\].attributeReturn=\"member\" \
--set idp.${BACKEND_AUTH}.eduPersonAffiliationAttributeMap.valueMap\[1\].attributeValues\[0\]=\"@${STAFF_EMAIL_DOMAIN}\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.attribute=\"eduPersonAffiliation\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[0\].attributeReturn=\"urn:mace:${ORG_DOMAIN}:staff\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[0\].attributeValues\[0\]=\"staff\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[1\].attributeReturn=\"urn:mace:${ORG_DOMAIN}:member\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[1\].attributeValues\[0\]=\"member\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[2\].attributeReturn=\"urn:mace:dir:entitlement:common-lib-terms\" \
--set idp.${BACKEND_AUTH}.eduPersonEntitlementAttributeMap.valueMap\[2\].attributeValues\[0\]=\"member\""
        fi
    fi
# configurations specific to vikings backend authenticator
else
    helm_command="${helm_command} \
--set idp.${BACKEND_AUTH}.database_hostname=\"${DB_HOSTNAME}\" \
--set idp.${BACKEND_AUTH}.database_name=\"${DB_NAME}\" \
--set idp.${BACKEND_AUTH}.database_username=\"${DB_USER}\" \
--set idp.${BACKEND_AUTH}.database_password=\"${DB_PASSWORD}\""
fi

# perform helm command or a dry run
if [ "${DRY_RUN}" = "1" ]; then
    helm_command="${helm_command} --debug --dry-run"
else
    helm_command="${helm_command} --wait"
fi

# run helm install or upgrade
echo "Running helm ${CHART_OPERATION} for the organisation (${SHORT_ORG_NAME})"
eval ${helm_command}

# download shibboleth metadata post-installation
if [ "${CHART_OPERATION}" == "install" ] && [ "${DRY_RUN}" != "1" ]; then
    download_when_ready ${SHIB_METADATA_FILE} ${SHIB_METADATA_URL} "shibboleth metadata"
fi