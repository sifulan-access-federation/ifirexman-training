# Setting Up SSO Test Service

## Overview

This tutorial provides step-by-step instructions on how to set up an SSO Test service using the Helm chart developed by [SIFULAN Malaysian Access Federation](https://sifulan.my).

## Prerequisites

You need to have the following setup before you can proceed with this tutorial:

- Register a sub-domain for the SSO Test service. For example, `ssotest.ifirexman.edu`.

- Complete the [Federation core services](federationcore.md) tutorial.

- Add/copy your federation signer certificate, as a `fed-signer.crt` file, to your working folder.

- Add the `ifirexman` repository to Helm.

    ```bash
    helm repo add ifirexman https://sifulan-access-federation.github.io/ifirexman-charts
    ```

- Optional: These configurations are included in the `ssotest` chart. However, you can add them to your working folder if you require further customisation:

    - `shibboleth2.xml`: Shibboleth SP configuration file.

    - `attribute-map.xml`: Attribute mapping file.

    - `servername.conf`: Apache configuration file.

## Installation

1. Generate the signing and encryption keypairs.

    ```bash
    openssl req -newkey rsa:3072 -new -x509 -days 3652 -nodes -out signing.crt -keyout signing.pem
    openssl req -newkey rsa:3072 -new -x509 -days 3652 -nodes -out encrypt.crt -keyout encrypt.pem
    ```
    
2. Edit the `values.yaml` file (see [the example](../manifest/ssotest/values.yaml) at the `ssotest` sub-folder inside the `manifest` folder). A brief explanation and sample entries are provided in the file and in the [Parameters](#parameters) section.

3. Install the `ssotest` chart as `ifirexman-ssotest` to the `central-svcs` namespace. Only include and uncomment the commented lines if you require custom configurations and have them in your working folder.

    ```bash
    helm install ifirexman-ssotest -n central-svcs \
    --set-file ssotest.signing_crt="signing.crt" \
    --set-file ssotest.signing_key="signing.key" \
    --set-file ssotest.encryption_crt="encrypt.crt" \
    --set-file ssotest.encryption_key="encrypt.key" \
    --set-file federation.signer="fed-signer.crt" \
    # --set-file ssotest.sp_config="shibboleth2.xml" \
    # --set-file ssotest.attribute_map="attribute-map.xml" \
    # --set-file ssotest.apache_config="servername.conf" \
    -f values.yaml --wait ifirexman/ifirexman-ssotest
    ```

## Uninstallation

Run helm uninstall to uninstall the `ifirexman-ssotest` release.

    ```bash
    helm uninstall ifirexman-ssotest -n central-svcs
    ```

## Upgrade

1. Edit the `values.yaml` file as you would for the initial installation, with the additional changes you require.

2. Run helm upgrade to update the `ifirexman-ssotest` release. Only include and uncomment the commented lines if you require custom configurations and have them in your working folder.

    ```bash
    helm upgrade ifirexman-ssotest -n central-svcs \
    --set-file ssotest.signing_crt="signing.crt" \
    --set-file ssotest.signing_key="signing.key" \
    --set-file ssotest.encryption_crt="encrypt.crt" \
    --set-file ssotest.encryption_key="encrypt.key" \
    --set-file federation.signer="fed-signer.crt" \
    # --set-file ssotest.sp_config="shibboleth2.xml" \
    # --set-file ssotest.attribute_map="attribute-map.xml" \
    # --set-file ssotest.apache_config="servername.conf" \
    -f values.yaml --wait ifirexman/ifirexman-ssotest
    ```

## Helm Charts Parameters

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| federation.metadata_url | string | `""` | Federation Manager Metadata URL. |
| federation.name | string | `""` | Federation full name. |
| federation.signer | file | `""` | Federation signing certificate, `fed-signer.crt`. |
| federation.support | string | `""` | Federation support email address. |
| image.shibd.pullPolicy | string | `"IfNotPresent"` | Shibd container image pull policy. Defaults to `"IfNotPresent"`. |
| image.shibd.registry | string | `"ghcr.io"` | Shibd container image registry. Defaults to `"ghcr.io"`. |
| image.shibd.repository | string | `"sifulan-access-federation/ifirexman-shibboleth-sp"` | Shibd container image repository. Defaults to `"sifulan-access-federation/ifirexman-shibboleth-sp"`. |
| image.shibd.tag | string | `"0.1.0"` | Shibd container image version. Defaults to `"0.1.0"`. |
| image.ssotest.pullPolicy | string | `"IfNotPresent"` | SSO Test container image pull policy. Defaults to `"IfNotPresent"`. |
| image.ssotest.registry | string | `"ghcr.io"` | SSO Test container image registry. Defaults to `"ghcr.io"`. |
| image.ssotest.repository | string | `"sifulan-access-federation/ifirexman-ssotest"` | SSO Test container image repository. Defaults to `"sifulan-access-federation/ifirexman-ssotest"`. |
| image.ssotest.tag | string | `""` | SSO Test container image version. Defaults to Chart `appVersion`. |
| ingress.clusterIssuers | string | `"letsencrypt-http-prod"` | Ingress cluster issuer. Defaults to `"letsencrypt-http-prod"`. |
| replicaCount | int | `1` | Number of replicas of the SSO Test Portal. Defaults to `1`. |
| resources.shibd.limits.cpu | string | `"1"` | Shibd container maximum CPU allocation. |
| resources.shibd.limits.memory | string | `"2Gi"` | Shibd container maximum memory allocation. |
| resources.shibd.requests.cpu | string | `"0.5"` | Shibd container minimum CPU allocation. |
| resources.shibd.requests.memory | string | `"1Gi"` | Shibd container minimum memory allocation. |
| resources.ssotest.limits.cpu | string | `"1"` | SSO Test container maximum CPU allocation. |
| resources.ssotest.limits.memory | string | `"1Gi"` | SSO Test container maximum memory allocation. |
| resources.ssotest.requests.cpu | string | `"0.5"` | SSO Test container minimum CPU allocation. |
| resources.ssotest.requests.memory | string | `"0.5Gi"` | SSO Test container minimum memory allocation. |
| ssotest.apache_config | file | `""` | **Optional:** Custom Apache config, `servername.conf`. |
| ssotest.attribute_map | file | `""` | **Optional:** Custom Shibboleth attribute mapping, `attribute-map.xml`. |
| ssotest.domain | string | `""` | SSO Test portal domain. |
| ssotest.encryption_crt | file | `""` | Shibboleth SP encryption certificate, `encrypt.crt`. |
| ssotest.encryption_key | file | `""` | Shibboleth SP encryption key, `encrypt.key`. |
| ssotest.entity_id | string | `""` | SSO Test Shibboleth Entity ID. |
| ssotest.signing_crt | file | `""` | Shibboleth SP signing certificate, `signing.crt`. |
| ssotest.signing_key | file | `""` | Shibboleth SP signing key, `signing.key`. |
| ssotest.sp_config | file | `""` | **Optional:** Custom Shibboleth SP config, `shibboleth2.xml`. |
| ssotest.support | string | `""` | Support email address. |

## Adding the SSO/Attribute Release Test service to Federation Manager

To enable the SSO/Attribute Release Test service to be used as a test service for your federation, you must add it to Federation Manager. To do this, follow the steps below:

1. Download the Shibboleth SP metadata from your SSO Test/Attribute Release service (e.g. `ssotest.ifirexman.edu`).

    ```bash
    curl -Lo ssotest-metadata.xml https://ssotest.ifirexman.edu/Shibboleth.sso/Metadata
    ```

2. Log in to your Federation Manager (e.g. https://fedmanager.ifirexman.edu) as an Administrator.

3. Click the **Register** tab from the top menu, then click **Service Provider**.

4. Copy the contents of the `ssotest-metadata.xml` file into the **Metadata** field, then click the **Next** button.

5. From the **General** tab within the **Service Provider registration form**, select your federation from the **Federation** dropdown menu.

6. Click the **Organization** tab, and add your values to the following fields by clicking the **Add in new language** button:
    
        - Name of organization
        - Displayname of organization
        - URL to information about organization

7. Click the **Contacts** tab, and click **Add contact**. Select the **Support** contact type from the **Type** dropdown menu, and add your values to the following fields:
    
        - Given name
        - Surname
        - Email

8. Click the **UI Information** tab, and add your values to the following fields by clicking the **Add in new language** button:
    
        - Name of the Service
        - Description of the Service
        - URL to information about the Service

9. To assign a logo:
   
   1.  In the **Logo of Service** section, fill in the **URL** field with the URL of your logo image, and click the **Get logo** button.
   2.  Click the **unspecified** dropdown, and select the **English (en)** language.
   3.  Finally, click the **Add** button under the **Get logo** button to register the service's logo.

10. Click the **Required Attributes** tab, and remove the default attribute that has been automatically added (e.g. **transientId**) by clicking the **Remove** button next to the attribute.

11. Now, add the following attributes (if available) by selecting them from the available dropdown menu, and clicking the **Add** button:
    
        - givenName
        - surname
        - eduPersonAffiliation
        - mail
        - eduPersonTargetedID
        - eduPersonEntitlement
        - eduPersonScopedAffiliation
        - eduPersonPrincipalName
        - displayName
        - commonName
        - uid
        - schacHomeOrganization
        - schacHomeOrganizationType
        - schacCountryOfResidence
        - schacPersonalPosition
        - schacPersonalUniqueCode
        - schacPersonalUniqueID
        - samlSubjectID
        - samlPairwiseID

12. The attributes that have been added should be set as **required** by default. For the following attributes, set them as optional by clicking its corresponding **required** dropdown menu, and select **desired**: 
    
        - commonName
        - uid
        - schacPersonalPosition
        - schacPersonalUniqueCode
        - schacPersonalUniqueID

13. Click the **Register** button and approve the registration request.

14. Click the **Flag** or the numbered icon at the top right of the page.

15. Click the **Rightward arrow** icon of the SP we have added.

16. Scroll through the SP's registration form, and click the **Accept request** button at the bottom of the page to approve the SSO Test service registration.
