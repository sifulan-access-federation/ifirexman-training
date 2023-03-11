# Setting Up eduroam IdP as a Service

## Overview

This tutorial provides step-by-step instructions on how to set up an [Letswifi Portal](https://github.com/geteduroam/letswifi-portal) and eduroam IdP (RADIUS server) using the Helm chart developed by [SIFULAN Malaysian Access Federation](https://sifulan.my/). This is the base for the eduroam IdP as a service that you could offer to your potential Federation members. This IdP will be unique per organization, hence you may need to deploy multiple IdPs for your Federation members and this tutorial is meant for each organization. The Letswifi Portal is a web-based eduroam onboarding portal that allows users to obtain eduroam credential and connection profile for their devices. The credential is in a form of digital certificate.

To obtain the credential, users will need to authenticate themselves using their institutional credentials (i.e. Shibboleth login). Once the user is authenticated, the portal will generate a credential in either eap-config, mobileconfig, or pcks12 format. The user can directly import the credential to their devices (.e.g. for the mobileconfig and pcks12 format) or use the [geteduroam](https://www.geteduroam.app) apps (.e.g. for the eap-config format). If the organization has the access to the [eduroam CAT](https://cat.eduroam.org), they could also create a profile and redirect the installer to the Letswifi Portal. In this type of set up, the user just need to download and install the geteduroam app, search for their organization, then authenticate themselves using their institutional credentials. After that the geteduroam app will configure eduroam on their devices. For more information about this type of set up, you can visit this url: [https://www.geteduroam.app/idp/cat/](https://www.geteduroam.app/idp/cat/).

## Prerequisites

You need to have the following setup before you can proceed with this tutorial:

- Register a sub-domain for the portal. For example, `letswifi.ifirexman.edu`.
- Register a sub-domain for the idp. For example, `radius.ifirexman.edu`.
- Have a working Shibboleth IdP and MDQ server.
- Allow connection to port 1812/udp for the RADIUS server.

## Letswifi Portal Installation and Configuration

1. Generate a self-sign host certificate for the Letswifi Portal. You can use the following command to generate the certificate:

    ```bash
    openssl req -x509 -newkey rsa:4096 -keyout cert.key -out cert.crt -days 3650 -nodes
    ```

2. Generate salt secret key for the Letswifi Portal. You can use the following command to generate the key:

    ```bash
    LC_CTYPE=C tr -c -d '0123456789abcdefghijklmnopqrstuvwxyz' </dev/urandom | dd bs=32 count=1 2>/dev/null;echo
    ```

    Save the generated key for later use.

3. Create a database at the MySQL server. You can refer to this [tutorial](https://github.com/sifulan-access-federation/ifirexman-training/blob/master/guides/mariadb.md#creating-a-database) how to create one. Please take note the database name, username, and password.

4. Import the Letswifi portal sql schema into the database:

    ```bash
    kubectl -n central-svcs exec -i mariadb-0 -- mysql -u [username] -p[password] [dbname] < manifest/letswifi/letswifi.mysql.sql
    ```

    Replace `[username]`, `[password]`, and `[dbname]` with the actual values from step 3.

5. Create a `values.yaml` file. Below is an example:

    ```yaml
    # Ingress Configuration.
    ingress:
      # The name of the cluster issuers for ingress. By default is set to letsencrypt with http01 challenge.
      # Default: "letsencrypt-http-prod"
      clusterIssuers: "letsencrypt-http-prod"

    # Number of replicas of this Let's Wifi Portal.
    # Default: 1
    replicaCount: 1

    # Container images used for the Let's Wifi Portal.
    image:
      # Let's Wifi Portal.
      letswifi:
        # Let's Wifi Portal image registry.
        # Default: "ghcr.io"
        registry: "ghcr.io"
        # Let's Wifi Portal image repository.
        # Default: "sifulan-access-federation/ifirexman-letswifi-portal"
        repository: "sifulan-access-federation/ifirexman-letswifi-portal"
        # Let's Wifi Portal image version.
        # Default: Chart appVersion
        tag: ""
        # Let's Wifi Portal image pull policy.
        # Default: "IfNotPresent"
        pullPolicy: "IfNotPresent"
      # The image pull secret used to pull images from a private registry.
      pullSecret: ""

    # Set the minimum and maximum number of memory and cpu for the containers.
    resources:
      requests:
        # Minimum CPU allocation.
        # Example:
        # cpu: "10m"
        cpu: "0.1"
        # Minimum memory allocation.
        # Example:
        # memory: "10Mi"
        memory: "1Gi"
      limits:
        # Maximum CPU allocation.
        # Example:
        # cpu: "2"
        cpu: "0.5"
        # Maximum memory allocation.
        # Example:
        # memory: "2Gi"
        memory: "2Gi"

    # SimpleSAMLphp configuration.
    ssphp:
      # A secret salt used by SimpleSAMLphp when it needs to generate a secure hash. You can use the command below to generate     one.
      # LC_CTYPE=C tr -c -d '0123456789abcdefghijklmnopqrstuvwxyz' </dev/urandom | dd bs=32 count=1 2>/dev/null;echo
      salt: ""
      # Set password for the admin user.
      adminpassword: ""
      # Set memcache host.
      # Example: memcached.eduroam.svc.cluster.local
      memcachehost: ""
      # Set metadata query host.
      # Example: mdq.ifirexman.edu
      mdqhost: ""
      # Set service email address.
      # Example: support@ifirexman.edu
      email: ""
      # Set public and private key for SAML encryption and signing. You can use the command below to generate one.
      # openssl req -x509 -newkey rsa:4096 -keyout cert.key -out cert.crt -days 3650 -nodes
      cert_public_key: ""
      cert_private_key: ""

    # Let's Wifi Portal configuration.
    letswifi:
      # Set the hostname of the Let's Wifi Portal.
      # Example: letswifi.ifirexman.edu
      hostname: ""
      # Set the database host.
      # Example: mariadb.central-svcs.svc.cluster.local
      db_host: ""
      # Set the database name.
      # Example: letswifi
      db_name: ""
      # Set the database user.
      # Example: letswifi
      db_user: ""
      # Set the database password.
      db_password: ""
      # Set the realm.
      # Example: ifirexman.edu
      realm: ""
      # Set the shibboleth IdP entity id.
      # Example: https://idp.ifirexman.edu/idp/shibboleth
      idp_entity_id: ""
      # Set the attribute name that will be used as user identifier.
      # Example: mail
      userIdAttribute: ""
      # Set the authorization attribute name.
      # Example: eduPersonScopedAffiliation
      authzAttribute: ""
      # Set the authorization attribute value that will be used to determine if the user is authorized.
      # Example:
      # authzAttributeValue:
      #   - member@ifirexman.edu
      authzAttributeValue: []
      # Set the admin users.
      # Example:
      # portal_admin:
      #   - admin@ifirexman.edu
      portal_admin: []
      # Set the signing cert to sign the mobileconfig profile.
      # This is optional, only of you want to sign the mobileconfig profile with a code signing certificate from a trusted CA.
      # Even if you set this, the mobileconfig profile will still be able to be installed on the device. However, it will be marked as untrusted.
      # You would need to convert the certificate to a single line PEM format. You can use the command below to convert it:
      # awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' [cert.crt]
      # Example:
      # signing_cert_public_key: "-----BEGIN CERTIFICATE-----\nMIIGXTCCBMWgAwIBAgIQdxXePq+WI2MNjun6QTJa4TANBgkqhkiG9w0BAQwFADBU\nMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQD\n...-----END CERTIFICATE-----\n"
      # signing_cert_private_key: "-----BEGIN RSA PRIVATE KEY-----\nMIIJKQIBAAKCAgEAjLYtwtfhkQRd93/pPFh1HDs86QN9N1r28tc0d1wUFElOmcVf\n...-----END RSA PRIVATE KEY-----\n"
      # signing_cert_private_key_passphrase: "password"
      # signing_cert_ca_certs:
      #   - "-----BEGIN CERTIFICATE-----\nMIIGGjCCBAKgAwIBAgIQYh1tDFIBnjuQeRUgiSEcCjANBgkqhkiG9w0BAQwFADBW\nMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMS0wKwYDVQQD\n...-----END CERTIFICATE-----\n"
      #   - "-----BEGIN CERTIFICATE-----\nMIIFbzCCBFegAwIBAgIQSPyTtGBVlI02p8mKidaUFjANBgkqhkiG9w0BAQwFADB7\nMQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYD\n...-----END CERTIFICATE-----\n"
      signing_cert_public_key: ""
      signing_cert_private_key: ""
      signing_cert_private_key_passphrase: ""
      signing_cert_ca_certs: []
      ```

6. Deploy the chart

   ```bash
   helm install letswifi --create-namespace --namespace letswifi-ifirexman -f values.yaml ifirexman/ifirexman-lets-wifi-portal
   ```

   If the installation is successful, you should see the output something like this:

   ```bash
   NAME: letswifi
   LAST DEPLOYED: Sat Mar 11 18:39:32 2023
   NAMESPACE: letswifi-ifirexman
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The Let's Wifi Portal for realm ifirexman.geteduroam.my is now installed and configured.

   Below are some important information regarding the installation:

   1. Entity ID: https://letswifi.ifirexman.edu/sp
   2. Metadata URL: https://letswifi.ifirexman.edu/simplesaml/module.php/saml/sp/metadata.php/default-sp

   You can now register the Let's Wifi Portal at your Federation Manager.

   To view/download the IdP's metadata, you can use the following commands:

   $ curl https://letswifi.ifirexman.edu/simplesaml/module.php/saml/sp/metadata.php/default-sp

   or visit the Metadata URL by using a web browser
   ```

7. Download the Letswifi portal's SAML metadata and register them at your Federation Manager.

8. Login into the Letswifi portal pod by using the following command:

   ```bash
   kubectl -n letswifi-ifirexman exec -it [letswifi portal pod's name] -- bash
   ```

   To find out the pod's name, you can use the following command:

   ```bash
    kubectl -n letswifi-ifirexman get pods
    ```

    For example:

    ```bash
    NAME                                                 READY   STATUS    RESTARTS   AGE
    letswifi-ifirexman-letswifi-portal-849b76554-jbvl8   1/1     Running   0          9m25s
    ```

    From here we can see that the pod's name is `letswifi-ifirexman-letswifi-portal-849b76554-jbvl8`. Hence, replace `[letswifi portal pod's name]` with `letswifi-ifirexman-letswifi-portal-849b76554-jbvl8` in the command above.

9. We need to register the realm, the key pair for the RADIUS server, get the signing CA's public key. To do so, go to the ```bin``` folder and run the following commands:

   ```bash
   cd bin
   ./add-realm.php ifirexman.edu 90
   ./server-sign.php ifirexman.edu radius.ifirexman.edu 720
   -----BEGIN EC PRIVATE KEY-----
   MHcCAQEEIJ0Wovc5DRrjESc+TD3Z6lEaAEvyni5r1rfXvmjQC2jioAoGCCqGSM49
   AwEHoUQDQgAEt2tqD1q5YooyasA8U3G34cEBRvKjY3sZ1I0431x+ld1CcdkN/0Dd
   qqtyb1YC2JnMARXiVXzw1p4ytg1KFCzdzw==
   -----END EC PRIVATE KEY-----
   -----BEGIN CERTIFICATE-----
   MIIB+jCCAaGgAwIBAgIBBTAKBggqhkjOPQQDAjAxMS8wLQYDVQQDDCZpZmlyZXht
   YW4uZ2V0ZWR1cm9hbS5teSBMZXQncyBXaS1GaSBDQTAeFw0yMzAzMTExMDU1NDZa
   Fw0yNjAzMTAxMDU1NDZaMCkxJzAlBgNVBAMMHnJhZGl1cy5pZmlyZXhtYW4uZ2V0
   ZWR1cm9hbS5teTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABLdrag9auWKKMmrA
   PFNxt+HBAUbyo2N7GdSNON9cfpXdQnHZDf9A3aqrcm9WAtiZzAEV4lV88NaeMrYN
   ShQs3c+jgbEwga4wHQYDVR0OBBYEFHSOdrmRCWa3WD8Ips6VtaZEZUqOMGAGA1Ud
   IwRZMFeAFPfyBLARXQweO45BM4gvQvDBItKNoTWkMzAxMS8wLQYDVQQDDCZpZmly
   ZXhtYW4uZ2V0ZWR1cm9hbS5teSBMZXQncyBXaS1GaSBDQYIIKAxdgiWUJgcwCQYD
   VR0TBAIwADALBgNVHQ8EBAMCA+gwEwYDVR0lBAwwCgYIKwYBBQUHAwEwCgYIKoZI
   zj0EAwIDRwAwRAIgN3gd0qnWOChA0Xb+SUmLCRbIEs3VUue9u98qI2t0AToCIDhj
   Owpzi3nuyhi8iHtgFFQcH019weiJyIdUgOolM6z7
   -----END CERTIFICATE-----
   ./get-signingca.php radius.ifirexman.edu
   -----BEGIN CERTIFICATE-----
   MIIB/TCCAaOgAwIBAgIIKAxdgiWUJgcwCgYIKoZIzj0EAwIwMTEvMC0GA1UEAwwm
   aWZpcmV4bWFuLmdldGVkdXJvYW0ubXkgTGV0J3MgV2ktRmkgQ0EwIBcNMjMwMzA5
   MTAwMzMzWhgPMjA3MzAyMjQxMDAzMzNaMDExLzAtBgNVBAMMJmlmaXJleG1hbi5n
   ZXRlZHVyb2FtLm15IExldCdzIFdpLUZpIENBMFkwEwYHKoZIzj0CAQYIKoZIzj0D
   AQcDQgAEsfKTG/dvg/teFTIRJpTAwqT4i6Jh+f93q7UThPjzsrYD3105IYdRNQVd
   OB/Cq/n9QA7YWUAlHxBwbilelrKns6OBojCBnzAdBgNVHQ4EFgQU9/IEsBFdDB47
   jkEziC9C8MEi0o0wYAYDVR0jBFkwV4AU9/IEsBFdDB47jkEziC9C8MEi0o2hNaQz
   MDExLzAtBgNVBAMMJmlmaXJleG1hbi5nZXRlZHVyb2FtLm15IExldCdzIFdpLUZp
   IENBgggoDF2CJZQmBzAPBgNVHRMBAf8EBTADAQH/MAsGA1UdDwQEAwIBhjAKBggq
   hkjOPQQDAgNIADBFAiEA9XrF4F2ZmckEWhFRO8AIbTs3TdWWKtxKk/CcHw8tRKQC
   IA0ObfB7vGfDLnrerdYGmIhLwOEG9FUKBSXHerQD+fHF
   -----END CERTIFICATE-----
   ```

   The ```add-realm.php``` at least needs two parameters: realm name, credential validity. In the example above, we set the validity for 90 days. Once the credential is expired, the user will be required to re-authenticate to obtain a new credential. The ```server-sign.php``` needs three parameters: realm name, radius server hostname, and validity. In the example above, we set the radius server hostname to ```radius.ifirexman.edu``` with 720 days validity. It means you need to regenerate a new key pair once the host certificate is expired by using the same command. The ```get-signingca.php``` command only needs one parameter: the radius server hostname.

   Please take note all the outputs from the above commands. We will need them later to setup the RADIUS server.

10. To check whether the Letswifi Portal generates the correct credential, you can visit the Letswifi Portal url (e.g. https://letswifi.ifirexman.edu), click at the ```Apps``` link on the left side, unhide the "Options for other platforms and professional users", and click at the "Generate a certificate for manual use". You will be asked to perform authentication at the Shibboleth IdP. After the authentication, you will be able to download the credential in three formats: mobileconfig (for iOS/MacOS), eap-config (for Android), and PCKS12. The latter one doesn't contains the network configuration for eduroam. Merely a user credential in PKCS12 format. Should you need to use the credential in PKCS12 format, the import password is ```pkcs12```.