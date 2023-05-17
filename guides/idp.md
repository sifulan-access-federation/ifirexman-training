# Setting Up Shibboleth IdP

## Overview

This tutorial provides step-by-step instructions on how to set up a Shibboleth IdP using the Helm chart developed by [SIFULAN Malaysian Access Federation](https://sifulan.my/).

This is the base for the IdP-as-a-Service (IdPaaS) that you could offer to your potential Federation members. This IdP will be unique per organisation, hence you may need to deploy multiple IdPs for your Federation members and this tutorial is meant for each organisation.


## Prerequisites

You need to have the following setup before you can proceed with this tutorial:

- Register a sub-domain for the idp. For example, `idp.ifirexman.edu`.

- [VIKINGS (Identity Management System)](vikings.md) if the IdP will be using **VIKINGS** as the backend authenticator.

- [Azure AD Integration](azure.md) if the IdP will be using **Azure AD** as the backend authenticator.

- [Google Directory](google.md) if the IdP will be using **Google Directory** as the backend authenticator.

## Shibboleth IdP Installation and Configuration

### Assisted Installation

At the moment, the assisted installation method only supports the **Azure AD** and **Google Directory** backend authenticators.

From the login node:

1. Install the [IdP installation script](../scripts/idp/install.sh) by linking it (e.g. `~/ifirexman-training/scripts/idp/install.sh`) to the `/usr/local/bin` folder:

    ```bash
    sudo ln -sf ~/ifirexman-training/scripts/idp/install.sh /usr/local/bin/idp-install
    ```

2. Create and get into the working folder (e.g. `ifirexman`):

    ```bash
    mkdir ifirexman
    cd ifirexman
    ```

3. Add the following files to the working folder:

    - `values.yaml` - Helm chart values file.
    - `fed-signer.crt` - Federation signer certificate.
    - `azure.xml` - Azure AD IdP metadata file if **Azure AD** is the backend authenticator.
    - `google.xml` - Google Directory IdP metadata file if **Google Directory** is the backend authenticator.

4. Edit the `values.yaml` file according to your IdP. Generally, you will only need to update the `Federation Configuration` section. A brief explanation and sample entries are provided in the file.

5. Add all of the required variables and others that you wish to override to your shell environment:

    | Variable | Description | Example | Default Value | Required |
    | --- | --- | --- | --- | --- |
    | LONG_ORG_NAME | The full name of the organisation where this IdP belongs to. | "iFIRExMAN Virtual Organization" | - | True |
    | SHORT_ORG_NAME | The short name/acronym of the organisation where this IdP belongs to. | "ifirexman" | - | True |
    | ORG_WEBSITE | The website url of the organisation where this IdP belongs to. | "https://ifirexman.edu" | - | True |
    | ORG_DOMAIN | The domain name of the IdP. | "ifirexman.edu" | - | True |
    | STAFF_EMAIL_DOMAIN | The IdP's staff email domain. | "ifirexman.edu" | - | True |
    | ORG_SUPPORT_EMAIL | The support email address of the organisation where this IdP belongs to. Should be a role-based email instead of a personal email. | "support@ifirexman.edu" | - | True |
    | SHIBBOLETH_SUBDOMAIN | The subdomain name of the IdP. | "idp.ifirexman.edu" | "idp.$ORG_DOMAIN" | False |
    | ORG_SCOPE | The scope name of the IdP. Typically set to the domain name. | "ifirexman.edu" | "$ORG_DOMAIN" | False |
    | STUDENT_EMAIL_DOMAIN | The IdP's student email domain. | "student.ifirexman.edu" | "-" | False |
    | VALUES_FILE | The `values.yaml` file containing the IdP's values required by `ifirexman-shibboleth-idp`. | "custom-values.yaml" | "values.yaml" | False |
    | FED_SIGNER_FILE | The Identity Federation signer certificate. | "custom-signer.crt" | "fed-signer.crt" | False |
    | AZURE_METADATA_FILE | Azure AD IdP metadata file. | "azure-idp-metadata.xml" | "azure.xml" | False |
    | GOOGLE_METADATA_FILE | Google Directory IdP metadata file. | "google-idp-metadata.xml" | "google.xml" | False |

    Use `export` to add these variables to your shell environment. For example:

    ```bash
    export LONG_ORG_NAME="iFIRExMAN Virtual Organization"
    export SHORT_ORG_NAME="ifirexman"
    ```

6. Run the installation script:

    ```bash
    idp-install
    ```

7. Copy the IdP's shibboleth metadata at `ifirexman-shib-metadata.xml` (if the `SHORT_ORG_NAME` is set to `ifirexman`) and register it to the Federation Manager (Jagger).

### Manual Installation

From the login node:

1. Create a working folder (e.g. `ifirexman`) and generate signing and encryption algorithms for the IdP:

    ```bash
    mkdir ifirexman
    cd ifirexman
    docker run -it --rm -v $PWD:/opt/shibboleth-idp/credentials ghcr.io/sifulan-access-federation/shibboleth-idp-base:4.2.1 /scripts/install.sh IDP_DOMAIN IDP_SCOPE
    ```

    Replace `IDP_DOMAIN` with the sub-domain you registered for the IdP (e.g. `idp.ifirexman.edu`) and `IDP_SCOPE` with the domain scope of the IdP  (e.g. `ifirexman.edu`).

2. Change the ownership of the files to the service user (e.g. `ifirexman`):

    ```bash
    sudo chown ifirexman: idp-* sealer-* secrets.properties
    ```

3. Copy your federation signer certificate (e.g. `fed-signer.crt`) and the IdP logo (e.g. `logo.png`) to the working folder.

4. Generate a random string for the persistentId salt:

    ```bash
    openssl rand -base64 32
    ```

    Copy the output and save it for later use.

5. Edit the `secrets.properties` file, and uncomment the `idp.persistentId.salt` option and replace its value from:

    ```bash
    idp.persistentId.salt = changethistosomethingrandom
    ```

    with the random string you generated in the previous step. Below is an example:

    ```bash
    idp.persistentId.salt = /X81vwg0l1SYBfgzYLid8CCXx3Zz6y123pKDKQAMuPU=
    ```

6. If your IdP will be using `Azure AD` as the backend authenticator, copy your Azure AD IdP metadata file (i.e. `azure.xml`) to the working folder. If your IdP will be using `Google Directory` as the backend authenticator, copy your Google Directory IdP metadata file (i.e. `google.xml`) to the working folder.

7. Edit the `values.yaml` file (see an example [here](../manifest/idp/values.yaml)). Generally, there are 2 sections that you would need to update: `IdP Configuration` and `Federation Configuration`. A brief explanation and sample entries are provided in the file.

8. Add the `ifirexman` repository to Helm:

    ```bash
    helm repo add ifirexman https://sifulan-access-federation.github.io/ifirexman-charts
    ```

9. Below is an example to install the chart with the release name `ifirexman` with `VIKINGS` as the backend authenticator (set at the `values.yaml` file):

    ```bash
    helm install ifirexman \
    --namespace ifirexman \
    --create-namespace \
    --values values.yaml \
    --set idp.sealer_jks="$(base64 sealer.jks)" \
    --set-file idp.signing_cert=idp-signing.crt \
    --set-file idp.signing_key=idp-signing.key \
    --set-file idp.encryption_cert=idp-encryption.crt \
    --set-file idp.encryption_key=idp-encryption.key \
    --set-file federation.signer_cert=fed-signer.crt \
    --set-file idp.sealer_kver=sealer.kver \
    --set-file idp.secrets_properties=secrets.properties \
    --wait ifirexman/ifirexman-shibboleth-idp
    ```

    Below is an example to install the chart with the release name `ifirexman` with `Azure AD` as the backend authenticator (set at the `values.yaml` file):

    ```bash
    helm install ifirexman \
    --namespace ifirexman \
    --create-namespace \
    --values values.yaml \
    --set idp.sealer_jks="$(base64 sealer.jks)" \
    --set-file idp.signing_cert=idp-signing.crt \
    --set-file idp.signing_key=idp-signing.key \
    --set-file idp.encryption_cert=idp-encryption.crt \
    --set-file idp.encryption_key=idp-encryption.key \
    --set-file federation.signer_cert=fed-signer.crt \
    --set-file idp.sealer_kver=sealer.kver \
    --set-file idp.secrets_properties=secrets.properties \
    --set-file idp.azure_ad.metadata=azure.xml \
    --wait ifirexman/ifirexman-shibboleth-idp
    ```

    And below is an example to install the chart with the release name `ifirexman` with `Google Directory` as the backend authenticator (set at the `values.yaml` file):

    ```bash
    helm install ifirexman \
    --namespace ifirexman \
    --create-namespace \
    --values values.yaml \
    --set idp.sealer_jks="$(base64 sealer.jks)" \
    --set-file idp.signing_cert=idp-signing.crt \
    --set-file idp.signing_key=idp-signing.key \
    --set-file idp.encryption_cert=idp-encryption.crt \
    --set-file idp.encryption_key=idp-encryption.key \
    --set-file federation.signer_cert=fed-signer.crt \
    --set-file idp.sealer_kver=sealer.kver \
    --set-file idp.secrets_properties=secrets.properties \
    --set-file idp.google.metadata=google.xml \
    --wait ifirexman/ifirexman-shibboleth-idp
    ```

10. When the IdP is ready, you can access the IdP's metadata at `https://idp.ifirexman.edu/idp/shibboleth` (replace `idp.ifirexman.edu` with the actual subdomain for the IdP). Copy/download the metadata and register it at the Federation Manager (Jagger).

## Uninstalling the Chart

To uninstall/delete the `ifirexman` deployment:

  ```bash
  helm uninstall ifirexman --namespace ifirexman
  ```

The command removes all the Kubernetes components associated with the chart and deletes the release.
