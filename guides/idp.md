# Setting Up Shibboleth IdP

## Overview

This tutorial provides step-by-step instructions on how to set up a Shibboleth IdP using the Helm chart developed by [SIFULAN Malaysian Access Federation](https://sifulan.my). This is the base for the IdP-as-a-Service (IdPaaS) that you could offer to your potential Federation members.

This IdP will be unique per organisation and this tutorial is meant to be replicated for each organisation.


## Prerequisites

You need to have the following setup before you can proceed with this tutorial:

- Register a subdomain for the IdP. For example, `idp.ifirexman.edu`.

- [VIKINGS (Identity Management System)](vikings.md) if the IdP will be using **VIKINGS** as the backend authenticator.

- [Azure AD Integration](azure.md) if the IdP will be using **Azure AD** as the backend authenticator.

- [Google Directory Integration](google.md) if the IdP will be using **Google Directory** as the backend authenticator.

## Shibboleth IdP Installation and Configuration

This deployment is meant for each organisation that would like to use your Shibboleth IdPaaS service. It is highly recommended to create a dedicated working folder and Kubernetes namespace for each deployment to avoid confusion and also for ease of management.

Before proceeding with the installation using the [Assisted Installation](#assisted-installation) or the [Manual Installation](#manual-installation) method, detailed below are some common things that you will need to do.

From the login node:

1. Create a working folder for the IdP deployment (i.e. `ifirexman-organisation`):

    ```bash
    mkdir ifirexman-organisation && cd ifirexman-organisation
    ```

2. Add/copy the following files for the IdP deployment to the working folder:

    - [`values.yaml`](../manifest/idp/values.yaml) - Helm chart values file.
    - `fed_signer.crt` - Federation signer certificate.
    - `azure.xml` - Azure AD IdP metadata file **if** Azure AD is the backend authenticator. You can refer to [this guide](azure.md) on how to setup your Azure AD and obtain the metadata file.
    - `GoogleIDPMetadata.xml` - Google Directory IdP metadata file **if** Google Directory is the backend authenticator. You can refer to [this guide](google.md) on how to setup your Google Directory and obtain the metadata file.

### Assisted Installation

The assisted installation method supports the **Azure AD**, **Google Directory**, and **VIKINGS** backend authenticators. However, you should only choose **ONE** backend authenticator as this Shibboleth IdPaaS does not support multiple backend authenticators for a single IdP.

From the login node:

1. Install the [IdP installation script](../scripts/idp/install.sh) by linking it from this repo locally (i.e. `~/ifirexman-training/scripts/idp/install.sh`) to the `/usr/local/bin` folder:

    ```bash
    sudo ln -sf ~/ifirexman-training/scripts/idp/install.sh /usr/local/bin/idp-install
    ```

2. Edit the `values.yaml` file according to your IdP. Generally, you will **ONLY** need to update the `Federation Configuration` section. A brief explanation and sample entries are provided in the file.

3. Start the installation process by running the installation script:

    ```bash
    idp-install
    ```

4. You will be prompted to enter some values pertaining to your IdP. The required variables are detailed in the table below:

    | Variable | Description | Example | Default Value | Required |
    | --- | --- | --- | --- | --- |
    | BACKEND_AUTH | The backend authenticator of the IdP. | `azure_ad`, `google`, or `vikings` | `vikings` | True |
    | ORG_LONGNAME | The full name of the organisation where this IdP belongs to. | `iFIRExMAN Virtual Organisation` | - | True |
    | ORG_SHORTNAME | The short name/acronym of the organisation where this IdP belongs to. | `ifirexman` | - | True |
    | ORG_NAMESPACE | The Kubernetes namespace where the IdP will be deployed to. | `example` | `$ORG_SHORTNAME` | True |
    | ORG_COUNTRY | The country code (in lower letter) of the organisation where this IdP belongs to. | `au`, `my`, `sg`, `th`, etc. | `my` | True |
    | ORG_WEBSITE | The website url of the organisation where this IdP belongs to. | `https://ifirexman.edu` | - | True |
    | ORG_SUPPORT_EMAIL | The support email address of the organisation where this IdP belongs to. Should be a role-based email instead of a personal email. | `support@ifirexman.edu` | - | True |
    | ORG_DOMAIN | The domain name of the IdP. | `ifirexman.edu` | - | True |
    | ORG_SCOPE | The scope name of the IdP. Typically set to the domain name. | `ifirexman.edu` | `$ORG_DOMAIN` | True |
    | ORG_SHIB_SUBDOMAIN | The subdomain name of the IdP. | `idp.ifirexman.edu` | `idp.$ORG_DOMAIN` | True |
    | ORG_PWD_RESET_URL | The password reset url of the organisation where this IdP belongs to. | `https://ifirexman.edu/password-reset` | `#` | True |
    | STAFF_EMAIL_DOMAIN | The IdP's staff email domain. | `ifirexman.edu` | `$ORG_DOMAIN` | True **if** using **Azure AD** or **Google Directory** as the backend authenticator |
    | STUDENT_EMAIL_DOMAIN | The IdP's student email domain. | `student.ifirexman.edu` | `-` | True **if** using **Azure AD** or **Google Directory** as the backend authenticator |
    | DB_HOSTNAME | The hostname or IP address of the database server used by VIKINGS. | `mariadb.central-svcs.svc.cluster.local` | - | True **if** using **VIKINGS** as the backend authenticator |
    | DB_NAME | The name of the database used by VIKINGS. | `vikings` | - | True **if** using **VIKINGS** as the backend authenticator |
    | DB_USER | The username or user account for accessing the VIKINGS database. | `vikings` | - | True **if** using **VIKINGS** as the backend authenticator |
    | DB_PASSWORD | The password associated with the VIKINGS database user. | `vikings` | - | True **if** using **VIKINGS** as the backend authenticator |

5. After providing the required values and confirming them, the installation process will begin automatically.

6. At the end of the installation process, copy the content of the IdP's Shibboleth metadata file (i.e. `ifirexman-shib-metadata.xml` if the `ORG_SHORTNAME` is set to `ifirexman`) and register it to the Federation Manager (Jagger).

### Manual Installation

From the login node:

1. Get into the working folder (i.e. `ifirexman-organisation`) and generate signing and encryption algorithms for the IdP:

    ```bash
    cd ifirexman-organisation
    docker run -it --rm -v $PWD:/opt/shibboleth-idp/credentials ghcr.io/sifulan-access-federation/shibboleth-idp-base:4.2.1 /scripts/install.sh $IDP_DOMAIN $IDP_SCOPE
    ```

    Replace `$IDP_DOMAIN` with the subdomain you registered for the IdP (i.e. `idp.ifirexman.edu`) and `$IDP_SCOPE` with the domain scope of the IdP  (i.e. `ifirexman.edu`).

2. Change the ownership of the files to the service user (i.e. `ifirexman`):

    ```bash
    sudo chown ifirexman: idp-* sealer.jks secrets.properties
    ```

3. Generate a random string for the persistentId salt:

    ```bash
    openssl rand -base64 32
    ```

    Copy the output and save it for later use.

4. Edit the `secrets.properties` file, and uncomment the `idp.persistentId.salt` option and replace its value from:

    ```bash
    #idp.persistentId.salt = changethistosomethingrandom
    ```

    with the random string you generated in the previous step and remove the comment (`#`) as well. Below is an example:

    ```bash
    idp.persistentId.salt = /X81vwg0l1SYBfgzYLid8CCXx3Zz6y123pKDKQAMuPU=
    ```

5. Edit the `values.yaml` file (see an example [here](../manifest/idp/values.yaml)). Generally, there are 2 sections that you would need to update: `IdP Configuration` and `Federation Configuration`. A brief explanation and sample entries are provided in the file.

6. Add the `ifirexman` repository to Helm:

    ```bash
    helm repo add ifirexman https://sifulan-access-federation.github.io/ifirexman-charts
    ```

7. Below is an example to install the chart with the release name `ifirexman-organisation` with `VIKINGS` as the backend authenticator (set at the `values.yaml` file):

    ```bash
    helm install ifirexman-organisation \
    --namespace ifirexman-organisation \
    --create-namespace \
    --values values.yaml \
    --set idp.sealer_jks="$(base64 sealer.jks)" \
    --set-file idp.signing_cert=idp-signing.crt \
    --set-file idp.signing_key=idp-signing.key \
    --set-file idp.encryption_cert=idp-encryption.crt \
    --set-file idp.encryption_key=idp-encryption.key \
    --set-file federation.signer_cert=fed_signer.crt \
    --set-file idp.sealer_kver=sealer.kver \
    --set-file idp.secrets_properties=secrets.properties \
    --wait ifirexman/ifirexman-shibboleth-idp
    ```

    Below is an example to install the chart with the release name `ifirexman-organisation` with `Azure AD` as the backend authenticator (set at the `values.yaml` file):

    ```bash
    helm install ifirexman-organisation \
    --namespace ifirexman-organisation \
    --create-namespace \
    --values values.yaml \
    --set idp.sealer_jks="$(base64 sealer.jks)" \
    --set-file idp.signing_cert=idp-signing.crt \
    --set-file idp.signing_key=idp-signing.key \
    --set-file idp.encryption_cert=idp-encryption.crt \
    --set-file idp.encryption_key=idp-encryption.key \
    --set-file federation.signer_cert=fed_signer.crt \
    --set-file idp.sealer_kver=sealer.kver \
    --set-file idp.secrets_properties=secrets.properties \
    --set-file idp.azure_ad.metadata=azure.xml \
    --wait ifirexman/ifirexman-shibboleth-idp
    ```

    And below is an example to install the chart with the release name `ifirexman-organisation` with `Google Directory` as the backend authenticator (set at the `values.yaml` file):

    ```bash
    helm install ifirexman-organisation \
    --namespace ifirexman-organisation \
    --create-namespace \
    --values values.yaml \
    --set idp.sealer_jks="$(base64 sealer.jks)" \
    --set-file idp.signing_cert=idp-signing.crt \
    --set-file idp.signing_key=idp-signing.key \
    --set-file idp.encryption_cert=idp-encryption.crt \
    --set-file idp.encryption_key=idp-encryption.key \
    --set-file federation.signer_cert=fed_signer.crt \
    --set-file idp.sealer_kver=sealer.kver \
    --set-file idp.secrets_properties=secrets.properties \
    --set-file idp.google.metadata=GoogleIDPMetadata.xml \
    --wait ifirexman/ifirexman-shibboleth-idp
    ```

8. When the IdP is ready, you can access the IdP's metadata at `https://idp.ifirexman.edu/idp/shibboleth` (replace `idp.ifirexman.edu` with the actual subdomain for the IdP). Copy/download the metadata and register it to the Federation Manager (Jagger).

## Uninstalling the Chart

To uninstall/delete the `ifirexman-organisation` deployment:

  ```bash
  helm uninstall ifirexman-organisation --namespace ifirexman-organisation
  ```

This command removes all the Kubernetes objects related with the release and deletes the release.
