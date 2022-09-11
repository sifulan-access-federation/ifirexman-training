# Setting Up Shibboleth IdP

## Overview

This tutorial provides step-by-step instructions on how to set up a Shibboleth IdP using the Helm chart developed by [SIFULAN Malaysian Access Federation](https://sifulan.my/).

This is the base for the IdP-as-a-Service (IdPaaS) that you could offer to your potential Federation members. This IdP will be unique per organization, hence you may need to deploy multiple IdPs for your Federation members

and this tutorial is meant for each organization.


### Prerequisites

You need to have the following setup before you can proceed with this tutorial:

- Setting up VIKINGS (Identity Management System) - [VIKINGS (Identity Management System)](guides/vikings.md).
- Register a sub-domain for the idp. For example, `idp.example.com`.


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

3. Edit the `values.yaml` file. Replace `idp.vikings.e-id.my` with the sub-domain you registered for the IdP (e.g. `idp.example.com`) and word `vikings` in the `shib-tls-cert-vikings` words with organization's short name (e.g. `example`). Below is an example of the `values.yaml` file with the sub-domain and word replaced:

    ```yaml
    replicaCount: 1

    image:
      shibboleth:
        registry: ghcr.io
        repository: sifulan-access-federation/ifirexman-shibboleth-idp-base
        tag: "0.1.0"
        pullPolicy: IfNotPresent
    
      httpd:
        registry: ghcr.io
        repository: sifulan-access-federation/shibboleth-idp-httpd
        tag: "master"
        pullPolicy: IfNotPresent
    
    ingress:
      enabled: true
      className: "nginx"
      annotations:
        #cert-manager.io/cluster-issuer: letsencrypt-http-prod
        nginx.ingress.kubernetes.io/affinity: cookie
        nginx.ingress.kubernetes.io/affinity-mode: persistent
        nginx.ingress.kubernetes.io/proxy-body-size: 100m
        nginx.ingress.kubernetes.io/session-cookie-expires: '172800'
        nginx.ingress.kubernetes.io/session-cookie-max-age: '172800'
        nginx.ingress.kubernetes.io/session-cookie-name: route
        nginx.org/client-max-body-size: 100m
      hosts:
        - host: idp.example.com
          paths:
            - path: /
              pathType: Prefix
      tls:
        - hosts:
            - idp.example.com
          #secretName: shib-tls-cert-example
    
    resources:
      limits:
        cpu: '1'
        memory: 2Gi
      requests:
        cpu: '0.5'
        memory: 1Gi
    ```

4. Go to the `configs` directory and create a folder called credentials.

    ```bash
    cd configs
    mkdir credentials
    ```

5. Run the following command to generate key and certificate for the IdP:

    ```bash
    docker run -it --rm -v $PWD/credentials:/opt/shibboleth-idp/credentials ghcr.io/sifulan-access-federation/shibboleth-idp-base:4.2.1 /scripts/install.sh IDP_SUBDOMAIN IDP_DOMAIN
    ```

   Replace `IDP_SUBDOMAIN` with the sub-domain you registered for the IdP (e.g. `idp.example.com`) and `IDP_DOMAIN` with the domain you registered for the IdP (e.g. `example.com`).

6. Go to the `credentials` folder and change the ownership of the files to the service user (e.g. `ifirexman`)

    ```bash
    cd credentials
    sudo chown ifirexman: *
    ```

7. Edit the `secrets.properties` file and replace the `idp.example.com` with the sub-domain you registered for the IdP.

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

  8. Edit the `attribute-resolver.xml` file and replace the `example.com` with the domain you of the organization and replace the `Example Organization` with the name of the organization.

  9. Edit the `idp.properties` file and replace the `idp.example.com` with the sub-domain you registered for the IdP (e.g. `idp.example.com`) and `example.com` with the domain name of the organization.

  10. Edit the `metadata-based-attribute-filter.xml` file and replace the `FEDERATION` with the (short) name of your federation and replace `FEDERATION_REGISTRATION_AUTHORITY` with your federation registration authority name.

  11. Edit the `metadata-provider-mdq.xml` file and replace the `FEDERATION` with the (short) name of your federation and replace `mdq.example.com` with your federation mdq server.

  12. Copy your federation metadata signer public key to the `shibboleth/metadata` folder and name it as `FEDERATION-signer.pem` (you shall replace `FEDERATION` with the (short) name of your federation).

  13. Deploy the IdP:

      ```bash
      helm install ORG_SHORT_NAME --namespace ORG_SHORT_NAME --create-namespace ./
      ```
  
  14. Check the status of the IdP deployment:
  
      ```bash
      kubectl get pods -n ORG_SHORT_NAME
      ```
  
  15. When the IdP is ready, you can access the IdP's metadata at `https://idp.example.com/idp/shibboleth`. Copy/download the metadata and register it at the federation manager/jagger. 