#!/bin/bash

# function to check if all environment variables are set correctly
function check_env() {
    # check if all variables are set
    for var in "$@"
    do
        # check if all is set
        if [ -z "${!var}" ]; then
            # get value and make sure not empty and set to environment
            while [ -z "${!var}" ]; do
                read -p "$var = " value
                export "$var"="$value"
            done
        else
            echo "$var = \"${!var}\""
        fi
    done

    # check if user would like to continue with all values
    read -p "Would you like to continue with the above values? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
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
    # check the current directory for the file
    if [ -f "$1" ]; then
        echo "Required file is available ($1)"
    # exit with error if file is not found
    else
        echo "Required file is NOT FOUND ($1)"
        exit 1
    fi
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


# ================= DO NOT EDIT BEYOND THIS LINE =================


# get optional argument
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--chart)
            if [ -z "$2" ]; then
                echo "Please specify an installation chart!"
                exit 1
            fi
            CHART="$2"
            shift
            ;;
        *)
            echo "Invalid argument: $1"
            exit 1
            ;;
    esac
    shift
done

# check if all environment variables are set
check_env LONG_ORG_NAME SHORT_ORG_NAME ORG_DOMAIN ORG_WEBSITE ORG_SUPPORT_EMAIL STAFF_EMAIL_DOMAIN STUDENT_EMAIL_DOMAIN

# set ENV variables default values if not set
set_default SHIBBOLETH_SUBDOMAIN "sso.$ORG_DOMAIN" \
&& set_default ORG_SCOPE "$ORG_DOMAIN" \
&& set_default VALUES_FILE "values.yaml" \
&& set_default AZURE_METADATA_FILE "azure.xml" \
&& set_default FED_SIGNER_FILE "fed-signer.crt" \
&& set_default SHIB_METADATA_FILE "$SHORT_ORG_NAME-shib-metadata.xml" \
&& set_default SHIB_METADATA_URL "https://$SHIBBOLETH_SUBDOMAIN/idp/shibboleth"

# set installation chart
if [ -z "$CHART" ]; then
    echo "Adding/updating helm repo (ifirexman)"
    # add sifulan helm repo if haven't and update
    add_helm_repo "ifirexman" "https://raw.githubusercontent.com/sifulan-access-federation/ifirexman-charts/master"
    # set chart to default
    CHART="ifirexman/ifirexman-shibboleth-idp"
fi

# check if required files exist
check_local_file_exists $VALUES_FILE \
&& check_local_file_exists $AZURE_METADATA_FILE \
&& check_local_file_exists $FED_SIGNER_FILE

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
    if [ ! -f "$file" ]; then
        # determine container runtime
        if [ -x "$(command -v docker)" ]; then
            CONTAINER_RUNTIME="docker"
        elif [ -x "$(command -v podman)" ]; then
            CONTAINER_RUNTIME="podman"
        elif [ -x "$(command -v nerdctl)" ]; then
            CONTAINER_RUNTIME="nerdctl"
        else
            echo "You must have a supporting container runtime installed"
            exit 1
        fi
        
        # create shibboleth certificates
        echo "Creating shibboleth certificates"
        $CONTAINER_RUNTIME run -it --rm -v $PWD:/opt/shibboleth-idp/credentials ghcr.io/sifulan-access-federation/shibboleth-idp-base:4.2.1 /scripts/install.sh $SHIBBOLETH_SUBDOMAIN $ORG_DOMAIN

        # change ownership of the certificates
        echo "Changing ownership of the certificates to the user ($USER)"
        echo $SUDO_PASS | sudo -S chown -R $USER: .

        # set random salt for persistent ID
        echo "Setting random salt for persistent ID (secrets.properties)"
        salt=`openssl rand -hex 32` && sed "s/\#idp.persistentId.salt = changethistosomethingrandom/idp.persistentId.salt = `echo $salt`/" secrets.properties > secrets.properties.tmp && mv secrets.properties.tmp secrets.properties

        break
    fi
done

# extract the entity ID from the azure metadata file
echo "Extracting the entity ID from the azure metadata file ($AZURE_METADATA_FILE)"
ENTITY_ID=`xmllint --pretty 1 $AZURE_METADATA_FILE | grep wsa | grep sts | sed 's/        <wsa:Address>//' | sed 's/<\/wsa:Address>//'`

# determine if chart is to be installed or upgraded
echo "Checking if release exists in the namespace ($SHORT_ORG_NAME)"
if helm ls -n $SHORT_ORG_NAME | grep "$SHORT_ORG_NAME-idp" > /dev/null; then
    CHART_OPERATION="upgrade"
else
    CHART_OPERATION="install"
fi

# run helm install
echo "Running helm $CHART_OPERATION for the organisation ($SHORT_ORG_NAME)"
# sharing staff and student email domain
if [ "$STAFF_EMAIL_DOMAIN" == "$STUDENT_EMAIL_DOMAIN" ]; then
    helm $CHART_OPERATION $SHORT_ORG_NAME-idp \
    --namespace $SHORT_ORG_NAME \
    --create-namespace \
    --values $VALUES_FILE \
    --set idp.domain="$SHIBBOLETH_SUBDOMAIN" \
    --set idp.scope="$ORG_SCOPE" \
    --set idp.fullname="$LONG_ORG_NAME" \
    --set idp.shortname="$SHORT_ORG_NAME" \
    --set idp.website="$ORG_WEBSITE" \
    --set idp.support_email="$ORG_SUPPORT_EMAIL" \
    --set idp.vikings.enabled=false \
    --set idp.sealer_jks="$(base64 sealer.jks)" \
    --set-file idp.signing_cert=idp-signing.crt \
    --set-file idp.signing_key=idp-signing.key \
    --set-file idp.encryption_cert=idp-encryption.crt \
    --set-file idp.encryption_key=idp-encryption.key \
    --set-file idp.sealer_kver=sealer.kver \
    --set-file idp.secrets_properties=secrets.properties \
    --set idp.azure_ad.enabled=true \
    --set idp.azure_ad.entity_id="$ENTITY_ID" \
    --set idp.azure_ad.eduPersonAffiliationAttributeMap.attribute="mail" \
    --set idp.azure_ad.eduPersonAffiliationAttributeMap.valueMap\[0\].attributeReturn="member" \
    --set idp.azure_ad.eduPersonAffiliationAttributeMap.valueMap\[0\].attributeValues\[0\]="@$STAFF_EMAIL_DOMAIN" \
    --set idp.azure_ad.eduPersonEntitlementAttributeMap.attribute="eduPersonAffiliation" \
    --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[0\].attributeReturn="urn:mace:$ORG_DOMAIN:member" \
    --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[0\].attributeValues\[0\]="member" \
    --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[1\].attributeReturn="urn:mace:dir:entitlement:common-lib-terms" \
    --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[1\].attributeValues\[0\]="member" \
    --set-file idp.azure_ad.metadata=$AZURE_METADATA_FILE \
    --set-file federation.signer_cert=$FED_SIGNER_FILE \
    --wait $CHART
else
    # separate student and staff email domains
    if [ "$STUDENT_EMAIL_DOMAIN" != "-" ]; then
        helm $CHART_OPERATION $SHORT_ORG_NAME-idp \
        --namespace $SHORT_ORG_NAME \
        --create-namespace \
        --values $VALUES_FILE \
        --set idp.domain="$SHIBBOLETH_SUBDOMAIN" \
        --set idp.scope="$ORG_SCOPE" \
        --set idp.fullname="$LONG_ORG_NAME" \
        --set idp.shortname="$SHORT_ORG_NAME" \
        --set idp.website="$ORG_WEBSITE" \
        --set idp.support_email="$ORG_SUPPORT_EMAIL" \
        --set idp.vikings.enabled=false \
        --set idp.sealer_jks="$(base64 sealer.jks)" \
        --set-file idp.signing_cert=idp-signing.crt \
        --set-file idp.signing_key=idp-signing.key \
        --set-file idp.encryption_cert=idp-encryption.crt \
        --set-file idp.encryption_key=idp-encryption.key \
        --set-file idp.sealer_kver=sealer.kver \
        --set-file idp.secrets_properties=secrets.properties \
        --set idp.azure_ad.enabled=true \
        --set idp.azure_ad.entity_id="$ENTITY_ID" \
        --set idp.azure_ad.eduPersonAffiliationAttributeMap.attribute="mail" \
        --set idp.azure_ad.eduPersonAffiliationAttributeMap.valueMap\[0\].attributeReturn="staff" \
        --set idp.azure_ad.eduPersonAffiliationAttributeMap.valueMap\[0\].attributeValues\[0\]="@$STAFF_EMAIL_DOMAIN" \
        --set idp.azure_ad.eduPersonAffiliationAttributeMap.valueMap\[1\].attributeReturn="student" \
        --set idp.azure_ad.eduPersonAffiliationAttributeMap.valueMap\[1\].attributeValues\[0\]="@$STUDENT_EMAIL_DOMAIN" \
        --set idp.azure_ad.eduPersonAffiliationAttributeMap.valueMap\[2\].attributeReturn="member" \
        --set idp.azure_ad.eduPersonAffiliationAttributeMap.valueMap\[2\].attributeValues\[0\]="@$STAFF_EMAIL_DOMAIN" \
        --set idp.azure_ad.eduPersonAffiliationAttributeMap.valueMap\[2\].attributeValues\[1\]="@$STUDENT_EMAIL_DOMAIN" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.attribute="eduPersonAffiliation" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[0\].attributeReturn="urn:mace:$ORG_DOMAIN:staff" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[0\].attributeValues\[0\]="staff" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[1\].attributeReturn="urn:mace:$ORG_DOMAIN:student" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[1\].attributeValues\[0\]="student" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[2\].attributeReturn="urn:mace:$ORG_DOMAIN:member" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[2\].attributeValues\[0\]="member" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[3\].attributeReturn="urn:mace:dir:entitlement:common-lib-terms" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[3\].attributeValues\[0\]="member" \
        --set-file idp.azure_ad.metadata=$AZURE_METADATA_FILE \
        --set-file federation.signer_cert=$FED_SIGNER_FILE \
        --wait $CHART
    # single staff email domain with no student email domain
    else
        helm $CHART_OPERATION $SHORT_ORG_NAME-idp \
        --namespace $SHORT_ORG_NAME \
        --create-namespace \
        --values $VALUES_FILE \
        --set idp.domain="$SHIBBOLETH_SUBDOMAIN" \
        --set idp.scope="$ORG_SCOPE" \
        --set idp.fullname="$LONG_ORG_NAME" \
        --set idp.shortname="$SHORT_ORG_NAME" \
        --set idp.website="$ORG_WEBSITE" \
        --set idp.support_email="$ORG_SUPPORT_EMAIL" \
        --set idp.vikings.enabled=false \
        --set idp.sealer_jks="$(base64 sealer.jks)" \
        --set-file idp.signing_cert=idp-signing.crt \
        --set-file idp.signing_key=idp-signing.key \
        --set-file idp.encryption_cert=idp-encryption.crt \
        --set-file idp.encryption_key=idp-encryption.key \
        --set-file idp.sealer_kver=sealer.kver \
        --set-file idp.secrets_properties=secrets.properties \
        --set idp.azure_ad.enabled=true \
        --set idp.azure_ad.entity_id="$ENTITY_ID" \
        --set idp.azure_ad.eduPersonAffiliationAttributeMap.attribute="mail" \
        --set idp.azure_ad.eduPersonAffiliationAttributeMap.valueMap\[0\].attributeReturn="staff" \
        --set idp.azure_ad.eduPersonAffiliationAttributeMap.valueMap\[0\].attributeValues\[0\]="@$STAFF_EMAIL_DOMAIN" \
        --set idp.azure_ad.eduPersonAffiliationAttributeMap.valueMap\[1\].attributeReturn="member" \
        --set idp.azure_ad.eduPersonAffiliationAttributeMap.valueMap\[1\].attributeValues\[0\]="@$STAFF_EMAIL_DOMAIN" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.attribute="eduPersonAffiliation" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[0\].attributeReturn="urn:mace:$ORG_DOMAIN:staff" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[0\].attributeValues\[0\]="staff" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[1\].attributeReturn="urn:mace:$ORG_DOMAIN:member" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[1\].attributeValues\[0\]="member" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[2\].attributeReturn="urn:mace:dir:entitlement:common-lib-terms" \
        --set idp.azure_ad.eduPersonEntitlementAttributeMap.valueMap\[2\].attributeValues\[0\]="member" \
        --set-file idp.azure_ad.metadata=$AZURE_METADATA_FILE \
        --set-file federation.signer_cert=$FED_SIGNER_FILE \
        --wait $CHART
    fi
fi

# download shibboleth metadata post-installation
if [ "$CHART_OPERATION" == "install" ]; then
    download_when_ready $SHIB_METADATA_FILE $SHIB_METADATA_URL "shibboleth metadata"
fi