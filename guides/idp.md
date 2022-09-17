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

3. Edit the `values.yaml` file. Replace `idp.ifirexman.edu` with the sub-domain you registered for the IdP  and word `ifirexman` in the `shib-tls-cert-ifirexman` words with organization's short name in lower letter.

4. Go to the `configs` directory and create a folder called credentials.

    ```bash
    cd configs
    mkdir credentials
    ```

5. Run the following command to generate key and certificate for the IdP:

    ```bash
    docker run -it --rm -v $PWD/credentials:/opt/shibboleth-idp/credentials ghcr.io/sifulan-access-federation/shibboleth-idp-base:4.2.1 /scripts/install.sh IDP_SUBDOMAIN IDP_DOMAIN
    ```

   Replace `IDP_SUBDOMAIN` with the sub-domain you registered for the IdP (e.g. `idp.ifirexman.edu`) and `IDP_DOMAIN` with the domain you registered for the IdP (e.g. `ifirexman.edu`).

6. Go to the `credentials` folder and change the ownership of the files to the service user (e.g. `ifirexman`)

    ```bash
    cd credentials
    sudo chown ifirexman: *
    ```

7. Edit the `secrets.properties` file and replace the `idp.ifirexman.edu` with the sub-domain you registered for the IdP.

    ```bash
    vi secrets.properties
    ```

    add the following lines at the end of the file:

    ```bash
    idp.dbms.host = mariadb.central-svcs.svc.cluster.local
    idp.dbms.name = <database name>
    idp.dbms.username = <database username>
    idp.dbms.password = <database password>
    ```

    Replace `<database name>`, `<database username>` and `<database password>` with the database name, username and password you created for the IdP.

  8. Edit the `attribute-resolver.xml` file and replace the `ifirexman.edu` with the domain you of the organization and replace the `iFIRExMAN Virtual Organization` with the full name of the organization.

  9. Edit the `idp.properties` file and replace the `idp.ifirexman.edu` with the sub-domain you registered for the IdP and `ifirexman.edu` with the domain name of the organization.

  10. Edit the `metadata-based-attribute-filter.xml` file and replace the `FEDERATION` with the (short) name of your federation and replace `FEDERATION_REGISTRATION_AUTHORITY` with your federation registration authority name.

  11. Edit the `metadata-provider-mdq.xml` file and replace the `FEDERATION` with the (short) name of your federation and replace `mdq.ifirexman.edu` with your federation mdq server.

  12. Copy your federation metadata signer public key to the `shibboleth/metadata` folder and name it as `FEDERATION-signer.pem` (you shall replace `FEDERATION` with the (short) name of your federation).

  13. Deploy the IdP:

      ```bash
      helm install ORG_SHORT_NAME --namespace ORG_SHORT_NAME --create-namespace ./
      ```
  
  14. Check the status of the IdP deployment:
  
      ```bash
      kubectl get pods -n ORG_SHORT_NAME
      ```
  
  15. When the IdP is ready, you can access the IdP's metadata at `https://idp.ifirexman.edu/idp/shibboleth`. Copy/download the metadata and register it at the federation manager/jagger. 