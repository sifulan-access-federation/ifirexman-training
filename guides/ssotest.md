# Setting Up SSO Test Service

## Overview

This tutorial provides step-by-step instructions on how to set up an SSO Test service using the Helm chart developed by [SIFULAN Malaysian Access Federation](https://sifulan.my).

## Prerequisites

You need to have the following setup before you can proceed with this tutorial:

- Register a sub-domain for the SSO Test service. For example, `ssotest.ifirexman.edu`.

- Complete the [Federation core services](federationcore.md) tutorial.

- Generate the signing and encryption keypairs.

    Prepare `ssl.cnf`. Replace `$fqdn` and `$entityid` with your SSO Test (SP) hostname and entityID respectively.

    ```conf
    # OpenSSL configuration file for creating keypair
    [req]
    prompt=no
    default_bits=3072
    encrypt_key=no
    default_md=sha256
    distinguished_name=dn
    # PrintableStrings only
    string_mask=MASK:0002
    x509_extensions=ext
    [dn]
    CN=$fqdn
    [ext]
    subjectAltName=DNS:$entityid,URI:$entityid
    subjectKeyIdentifier=hash
    ```

    Generate keypairs for signing and encryption.

    ```bash
    openssl req -new -x509 -nodes -days 3652 -config ssl.cnf -out signing.crt -keyout signing.key
    openssl req -new -x509 -nodes -days 3652 -config ssl.cnf -out encrypt.crt -keyout encrypt.key
    ```

- Add your federation signer certificate, as a `fed-signer.crt` file, to your working folder.

- Add the `ifirexman` repository to Helm.

    ```bash
    helm repo add ifirexman https://sifulan-access-federation.github.io/ifirexman-charts
    ```

- Optional: These configurations are included in the `ssotest` chart. However, you can add them to your working folder if you require further customisation:

    - `shibboleth2.xml`: Shibboleth SP configuration file.

    - `attribute-map.xml`: Attribute mapping file.

    - `servername.conf`: Apache configuration file.

## Installation

1. Edit the `values.yaml` file (see an example at the `ssotest` sub-folder inside the `manifest` folder). A brief explanation and sample entries are provided in the file and in the [Parameters](#parameters) section.

2. Install the `ssotest` chart as `ifirexman-ssotest` to the `ifirexman` namespace. Only include and uncomment the commented lines if you require custom configurations and have them in your working folder.

    ```bash
    helm install ifirexman-ssotest -n ifirexman \
    --set-file ssotest.signing_crt="signing.crt" \
    --set-file ssotest.signing_key="signing.key" \
    --set-file ssotest.encryption_crt="encrypt.crt" \
    --set-file ssotest.encryption_key="encrypt.key" \
    --set-file ssotest.federation_signer="fed-signer.crt" \
    # --set-file ssotest.sp_config="shibboleth2.xml" \
    # --set-file ssotest.attribute_map="attribute-map.xml" \
    # --set-file ssotest.apache_config="servername.conf" \
    -f values.yaml --wait ifirexman/ssotest
    ```

## Uninstallation

Run helm uninstall to uninstall the `ifirexman-ssotest` release.

    ```bash
    helm uninstall ifirexman-ssotest -n ifirexman
    ```

## Upgrade

1. Edit the `values.yaml` file as you would for the initial installation, with the additional changes you require.

2. Run helm upgrade to update the `ifirexman-ssotest` release. Only include and uncomment the commented lines if you require custom configurations and have them in your working folder.

    ```bash
    helm upgrade ifirexman-ssotest -n ifirexman \
    --set-file ssotest.signing_crt="signing.crt" \
    --set-file ssotest.signing_key="signing.key" \
    --set-file ssotest.encryption_crt="encrypt.crt" \
    --set-file ssotest.encryption_key="encrypt.key" \
    --set-file ssotest.federation_signer="fed-signer.crt" \
    # --set-file ssotest.sp_config="shibboleth2.xml" \
    # --set-file ssotest.attribute_map="attribute-map.xml" \
    # --set-file ssotest.apache_config="servername.conf" \
    -f values.yaml --wait ifirexman/ssotest
    ```

## Parameters

| Key | Type | Default | Description |
|-----|------|---------|-------------|
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
| resources.shibd.limits.cpu | string | `"2Gi"` | Shibd container maximum CPU allocation. |
| resources.shibd.limits.memory | string | `"1"` | Shibd container maximum memory allocation. |
| resources.shibd.requests.cpu | string | `"1Gi"` | Shibd container minimum CPU allocation. |
| resources.shibd.requests.memory | string | `"0.5"` | Shibd container minimum memory allocation. |
| resources.ssotest.limits.cpu | string | `"1Gi"` | SSO Test container maximum CPU allocation. |
| resources.ssotest.limits.memory | string | `"1"` | SSO Test container maximum memory allocation. |
| resources.ssotest.requests.cpu | string | `"0.5Gi"` | SSO Test container minimum CPU allocation. |
| resources.ssotest.requests.memory | string | `"0.5"` | SSO Test container minimum memory allocation. |
| ssotest.apache_config | file | `""` | **Optional:** Custom Apache config, `servername.conf`. |
| ssotest.attribute_map | file | `""` | **Optional:** Custom Shibboleth attribute mapping, `attribute-map.xml`. |
| ssotest.domain | string | `""` | SSO Test portal domain. |
| ssotest.encryption_crt | file | `""` | Shibboleth SP encryption certificate, `encrypt.crt`. |
| ssotest.encryption_key | file | `""` | Shibboleth SP encryption key, `encrypt.key`. |
| ssotest.entity_id | string | `""` | SSO Test Shibboleth Entity ID. |
| ssotest.federation_signer | file | `""` | Shibboleth SP federation signing certificate, `fed-signer.crt`. |
| ssotest.fedmanager_metadata_url | string | `""` | Federation Manager Metadata URL. |
| ssotest.signing_crt | file | `""` | Shibboleth SP signing certificate, `signing.crt`. |
| ssotest.signing_key | file | `""` | Shibboleth SP signing key, `signing.key`. |
| ssotest.sp_config | file | `""` | **Optional:** Custom Shibboleth SP config, `shibboleth2.xml`. |
| ssotest.support | string | `""` | Support email address. |

## Adding the SSO Test service to Federation Manager

To be added.
