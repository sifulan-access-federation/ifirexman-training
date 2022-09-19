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

1. Clone iFIRExMAN Shibboleth IdP Helm chart repository:

    ```bash
    git clone https://github.com/sifulan-access-federation/ifirexman-shibboleth-idp.git ifirexman-shibboleth-idp-ORG_SHORT_NAME
    ```

   Replace ```ORG_SHORT_NAME``` with the organization's short name.

2. Open the `ifirexman-shibboleth-idp-ORG_SHORT_NAME` directory.

    ```bash
    cd ifirexman-shibboleth-idp-ORG_SHORT_NAME
    ```

3. Go to the `configs` folder and run the following command to generate key and certificate for the IdP:

    ```bash
    mkdir credentials
    docker run -it --rm -v $PWD/credentials:/opt/shibboleth-idp/credentials ghcr.io/sifulan-access-federation/shibboleth-idp-base:4.2.1 /scripts/install.sh IDP_DOMAIN IDP_SCOPE
    ```

   Replace `IDP_DOMAIN` with the sub-domain you registered for the IdP (e.g. `idp.ifirexman.edu`) and `IDP_SCOPE` with the domain scope of the IdP  (e.g. `ifirexman.edu`).

4. Go to the `credentials` folder and change the ownership of the files to the service user (e.g. `ifirexman`)

    ```bash
    cd credentials
    sudo chown ifirexman: *
    ```

5. Generate a random string for the persistentId salt:

    ```bash
    openssl rand -base64 32
    ```

    Copy the output and save it for later use.

6. Edit the `secrets.properties` file, and uncomment the `idp.persistentId.salt` option and replace its value from:

    ```bash
    idp.persistentId.salt = changethistosomethingrandom
    ```

    with the random string you generated in the previous step. Below is an example:

    ```bash
    idp.persistentId.salt=/X81vwg0l1SYBfgzYLid8CCXx3Zz6y123pKDKQAMuPU=
    ```

    If you are using VIKINGS as the backend authenticator, you need to add the following lines at the end of the file:

    ```bash
    idp.dbms.host = mariadb.central-svcs.svc.cluster.local
    idp.dbms.name = <database name>
    idp.dbms.username = <database username>
    idp.dbms.password = <database password>
    ```

    Replace `<database name>`, `<database username>` and `<database password>` with the database name, username and password you created for the IdP.

7. Back to the `ifirexman-shibboleth-idp-ORG_SHORT_NAME` folder and edit the `values.yaml` file. Generally, there are 2 sections that you would need to update: `IdP Configuration` and `Federation Configuration`. A brief explanation and sample entries are provided in the file. However, you need to pay attention for the following options:
   
   - `logo` : The logo of the organization should be in a base64 format. You can use the following command to convert the logo to base64 format:

        ```bash
        base64 <logo file>
        ```
      
      The recommended logo size is 300x50 pixels.

   - `signing_cert`, `backchannel_cert`, and `encryption_cert` : The value for these options should be the content of the certificate files in the `configs/credentials` folder (i.e.`idp-signing.crt`,`idp-backchannel.crt`, and `idp-encryption.crt`). You can use the following command to get the content of the certificate file:

        ```bash
        cat <certificate file>
        ```

    You shall omit the `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` lines.

   - `signer_cert` : The value for this option should be the content of the federation's signing certificate file (i.e. `cert.crt`). You can use the following command to get the content of the certificate file:

        ```bash
        cat <certificate file>
        ```

     You shall omit the `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` lines.

8. Deploy the IdP:

   ```bash
   helm install ORG_SHORT_NAME --namespace ORG_SHORT_NAME --create-namespace --wait --timeout 10m ./
   ```
  
9. Check the status of the IdP deployment:
  
   ```bash
   kubectl get pods -n ORG_SHORT_NAME
   ```
  
10. When the IdP is ready, you can access the IdP's metadata at `https://idp.ifirexman.edu/idp/shibboleth` (of course you need to replace `idp.ifirexman.edu` with the actual sub-domain for the IdP). Copy/download the metadata and register it at the federation manager/jagger. 