# Setting Up Shibboleth IdP

## Overview

This tutorial provides step-by-step instructions on how to set up a Shibboleth IdP using the Helm chart developed by [SIFULAN Malaysian Access Federation](https://sifulan.my/).

This is the base for the IdP-as-a-Service (IdPaaS) that you could offer to your potential Federation members. This IdP will be unique per organization, hence you may need to deploy multiple IdPs for your Federation members

and this tutorial is meant for each organization.


### Prerequisites

You need to have the following setup before you can proceed with this tutorial:

- Setting up VIKINGS (Identity Management System) - [VIKINGS (Identity Management System)](guides/vikings.md).
- Register a sub-domain for the idp. For example, `idp.ifirexman.edu`.

### Setting up Shibboleth IdP

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

6. If your IdP is using `Azure AD` as the backend authenticator, copy your Azure AD IdP metadata file (e.g. `azure.xml`) to the working folder.

7. Edit the `values.yaml` file (see an example at the `idp` sub-folder inside the `manifest` folder). Generally, there are 2 sections that you would need to update: `IdP Configuration` and `Federation Configuration`. A brief explanation and sample entries are provided in the file.

8. Add the `ifirexman` repository to Helm:

  ```bash
  helm repo add ifirexman https://sifulan-access-federation.github.io/ifirexman-charts
  ```

9. Below is an example to install the chart with the release name `ifirexman` with `VIKINGS` as the backend authenticator (set at the `values.yaml` file). If you are using `Azure AD` instead, uncomment the `--set-file idp.azure_ad.metadata=azure.xml` line:

  ```bash
  helm install ifirexman --namespace ifirexman --create-namespace \
  --set idp.sealer_jks="$(base64 sealer.jks)" \
  --set-file idp.signing_cert=idp-signing.crt \
  --set-file idp.signing_key=idp-signing.key \
  --set-file idp.encryption_cert=idp-encryption.crt \
  --set-file idp.encryption_key=idp-encryption.key \
  --set-file federation.signer_cert=fed-signer.crt \
  --set-file idp.sealer_kver=sealer.kver \
  --set-file idp.secrets_properties=secrets.properties \
  # --set-file idp.azure_ad.metadata=azure.xml \
  -f values.yaml --wait ifirexman/ifirexman-shibboleth-idp
  ```

10. When the IdP is ready, you can access the IdP's metadata at `https://idp.ifirexman.edu/idp/shibboleth` (replace `idp.ifirexman.edu` with the actual sub-domain for the IdP). Copy/download the metadata and register it at the Federation Manager (Jagger).

## Uninstalling the Chart

To uninstall/delete the `ifirexman` deployment:

  ```bash
  helm delete ifirexman --namespace ifirexman
  ```

The command removes all the Kubernetes components associated with the chart and deletes the release.
