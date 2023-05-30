# Setting Up Federation Core Services

This guide will walk you through setting up the core services for a federation. It is assumed that your federation have the following information:

- Federation short name: `iFIRExMAN`
- Federation long name: `iFIRExMAN Federation`
- Federation domain fqdn: `ifirexman.edu`
- Federation registration authority: `https://ifirexman.edu`
- Jagger domain name: `fedmanager.ifirexman.edu`
- MDQ domain name: `mdq.ifirexman.edu`
- WAYF domain name: `ds.ifirexman.edu`

You will need to replace the information/variables above with your own.

## Jagger

Jagger is a federation management tool developed by HEAnet to manage the Edugate multiparty SAML federation. Other organisations use Jagger to manage their federations but it can be used to manage the web-of-trust for a single entity.

For more detail about Jagger, you can watch the [Jagger video](https://www.youtube.com/watch?v=1REfW3N_On0) made by the [Australian Access Federation](https://www.aaf.edu.au) or read the [Jagger documentation](https://jagger.heanet.ie/docs/).

### Installation

From the login node:

1. Create a database for Jagger at MariaDB. You can refer at [MariaDB](mariadb.md) guide for more information. Take note of the database name, username and password which will be used in the next step.
2. Clone the [ifirexman-training](https://github.com/sifulan-access-federation/ifirexman-training) repository.

   ```bash
   git clone https://github.com/sifulan-access-federation/ifirexman-training.git
   ```

3. Open the `jagger` directory inside the `manifest` folder.

   ```bash
   cd ifirexman-training/manifest/jagger
   ```

4. Edit the `database.php` file and replace the database name, username and password with the ones you created in step 1.
5. Edit the `config_rr.php` file and update the `$config['syncpass']`, `$config['support_mailto']`, `$config['registrationAutority']` variables.
6. Edit the `config.php` file and update the `$config['base_url']` and the `$config['encryption_key']` variables.
7. Edit the `email.php` file and update the `$config['smtp_host']`, `$config['smtp_user']`, `$config['smtp_pass']` variables.
8. Create a secret for Jagger.

   ```bash
   kubectl create secret generic jagger-config --from-file=database.php --from-file=config_rr.php --from-file=config.php --from-file=email.php --from-file=memcached.php -n central-svcs
   ```
9.  Create a PVC for Jagger.

   ```bash
   kubectl apply -f pvc.yaml -n central-svcs
   ```

11. Deploy Jagger.

   ```bash
   kubectl apply -f deployment.yaml -n central-svcs
   ```

11. Create a service for Jagger.

   ```bash
   kubectl apply -f svc.yaml -n central-svcs
   ```

11. Edit the `ingress.yaml` file and update the `host` and `hosts` variables with your Jagger domain name.
12. Create an ingress for Jagger.

    ```bash
    kubectl apply -f ingress.yaml -n central-svcs
    ```

13. By using the `k9s` tool, login to the Jagger pod by locating the pod in the correct namespace, and press `s`.
14. Go to the `/opt/rr3/application` folder and run the following commands:

    ```bash
    ./doctrine orm:schema-tool:create
    ```
15. Quit from the pod by typing `exit` and press `Enter`, then type `ctrl+c` to exit from the `k9s` tool.
16. Open your web browser and go to Jagger URL (e.g. `https://fedmanager.ifirexman.edu/rr3/setup`) and create an admin account. You need to replace `fedmanager.ifirexman.edu` with your Jagger domain name.
17. Edit file `deployment.yaml` and set `RR_SETUP_ALLOWED` to `FALSE`.
18. Run the following command to update the deployment:

    ```bash
    kubectl apply -f deployment.yaml -n central-svcs
    ```
19. Wait for about 1 minute and go to Jagger's main url (e.g. `https://fedmanager.ifirexman.edu/rr3/`) and login with the admin account you created in step 16.
20. Go to `Administration` -> `System`. Click each `run process` button.

### Creating a Federation

To create a Federation:

1. Go to `Register` -> `Federation`.
2. Fill the `Internal/system name` with a short name of your federation (e.g. `iFIRExMAN`).
3. Fill the `Federation name` with the full name of your federation (e.g. `iFIRExMAN Federation`).
4. Fill the `Name in metadata` with the following format: `urn:mace:<federation domain fqdn in lower letter>:metadata:<metadata feed name>` (e.g. `urn:mace:ifirexman.edu:metadata:ifirexman`).
5. Fill the `Description` with some brief description of your federation.
6. Click the `Register` button, then click the `1` icon at the top right to approve this federation registration. Click at `->` button, then click the `Accept request` button.

You may repeat this step to create more federation.

## Metadata Signer

To ensure that the metadata feeds provided by a Federation operator is genuine, the metadata feeds are need to be digitally signed by the Federation operator. For this purpose, we will use a combination of [PyFF](https://pyff.io/) and [xmlsectool](https://shibboleth.atlassian.net/wiki/spaces/XSTJ3/overview) (for simplicity, we will call it as Metadata Signer). These tools that can be used to digitally sign metadata feeds.

The Metadata Signer will be deployed as a cronjob, which will periodically download the metadata from Jagger and sign it.

### Installation

From the login node:

1. Open the `signer` directory inside the `manifest` folder.

   ```bash
   cd ifirexman-training/manifest/signer
   ```

2. Generate a self-signed certificate and private key for the Metadata Signer. You can use the following command:

   ```bash
   openssl req -x509 -newkey rsa:4096 -keyout fed_key_unencrypted.key -out fed_signing.crt -days 3650 -nodes
   ```

   When running this command, openssl may ask you to enter some information. Below is an example of the information that you need to enter:

   ```bash
   You are about to be asked to enter information that will be incorporated
   into your certificate request.
   What you are about to enter is what is called a Distinguished Name or a DN.
   There are quite a few fields but you can leave some blank
   For some fields there will be a default value,
   If you enter '.', the field will be left blank.
   -----
   Country Name (2 letter code) [XX]:MY
   State or Province Name (full name) []:
   Locality Name (eg, city) [Default City]:Kuala Lumpur
   Organization Name (eg, company) [Default Company Ltd]:iFIRExMAN Federation
   Organizational Unit Name (eg, section) []:
   Common Name (eg, your name or your server's hostname) []:Metadata Signer
   Email Address []:
   ```

   OpenSSL will then generate a certificate and private key. You can use the following command to verify the certificate:

   ```bash
   openssl x509 -in fed_signing.crt -text -noout
   ```

   You need to create a copy of the private key that we just created and set it with a passphrase. You can use the following command:

   ```bash
   openssl rsa -aes256 -in fed_key_unencrypted.key -out fed_signing.key
   ```

   When running this command, openssl will ask you to enter a passphrase. You can enter any passphrase that you want. You will need to enter the passphrase when you configure the Metadata Signer.

   Now, let's validate all the keys that we just created:

   ```bash
   openssl rsa -in fed_signing.key -modulus -noout
   openssl rsa -in fed_key_unencrypted.key -modulus -noout
   openssl x509 -in fed_signing.crt -modulus -noout
   ```

   Make sure that all the modulus values are the same.

   You shall share the `fed_signing.crt` file with your federation members so that they can validate the metadata feed released by your federation. The trust of your federation relies on the signing key being secure. Hence, you MUST keep the `fed_signing.key` and `fed_unencrypted.key` files in a safe place/securely stored. Should you lost these files or compromised, you will need to immediately regenerate the certificate and private key, and inform your federation members to update their copy of the `fed_signing.crt` file.

3. Create a secret for the Metadata Signer.

   ```bash
   kubectl create secret generic metadata-signer-key --from-file=fed_signing.crt --from-file=fed_key_unencrypted.key --from-file=fed_signing.key -n central-svcs
   kubectl create secret generic metadata-signer-keypassword --from-literal=password=YOUR_PRIVATE_KEY_PASSPHRASE -n central-svcs
   ```

   Replace `YOUR_PRIVATE_KEY_PASSPHRASE` with the passphrase that you entered when you created the private key.

4. Edit the `sign.sh` file and update the `fedmanager.ifirexman.edu` domain with your Jagger domain name.

5. Edit the `update.sh` file and update the `iFIRExMAN` with your federation shortname set at Jagger. After that run the following command:

   ```bash
   kubectl create cm metadata-signer-update-sh --from-file=update.sh -n central-svcs
   kubectl create cm metadata-signer-sign-sh --from-file=sign.sh -n central-svcs
   ```

6. Edit the `edugain.fd` file and update the `https://ifirexman.edu` with your federation's registration authority name and `ifirexman.edu` with your federation domain fqdn in lower letter set at Jagger. After that run the following command:

   ```bash
   kubectl create cm metadata-signer-edugain-fd --from-file=edugain.fd -n central-svcs
   kubectl create cm metadata-signer-edugain-ca --from-file=eduGAIN-signer-ca.pem -n central-svcs
   ```

7. Edit the `full.fd` file and update the `iFIRExMAN` with your federation short name and `ifirexman.edu` with your federation domain fqdn in lower letter set at Jagger. After that run the following command:

   ```bash
   kubectl create cm metadata-signer-full-fd --from-file=full.fd -n central-svcs
   ```

8. Run the `metadata-signer` job by using the following command:

   ```bash
   kubectl apply -f sign.yaml -n central-svcs
   ```

  To check the status of the job, first we need to get the name of the pod by using the following command:

   ```bash
   kubectl get pods -n central-svcs
   ```

   ```bash
   NAME                        READY   STATUS    RESTARTS   AGE
   jagger-8559f84f58-bggq6     1/1     Running   0          84m
   mariadb-0                   1/1     Running   0          88m
   metadata-signer-job-f96pq   1/1     Running   0          42s
   ```

   From the output above, the name of the pod is `metadata-signer-job-f96pq`. We can then use the following command to check the status of the job:

   ```bash
   kubectl logs -f metadata-signer-job-f96pq -n central-svcs
   ```

   You should able to see the output from the pod. To stop the log stream, you can press `ctrl + c`.

   Note: If you would like to run the `metadata-signer` again, you need to delete the previous job first:

   ```bash
   kubectl delete -f sign.yaml -n central-svcs
   ```

9. Deploy the Metadata Signer.

   ```bash
   kubectl apply -f cron.yaml -n central-svcs
   ```

   Kuebernetes will create a job that will periodically (every 1 hour) download the metadata from Jagger and the eduGAIN, and sign it. The signed metadata will be accessible at ```https://fedmanager.ifirexman.edu/metadata.xml```, ```https://federation.ifirexman.edu/edugain-export-metadata.xml```, and ```https://fedmanager.ifirexman.edu/full-metadata.xml```. Of course you need to replace `ifirexman.edu` with your domain name.

## Metadata Query

The Metadata Query (MDQ) is a web service that can be used to query the metadata (on-demand) of a Federation operator. In comparison with the traditional method to download the full set of metadata file from the Federation operator, the MDQ allows Identity Provider or Service Provider to query the metadata of the entities that are requested only from the Federation operator. Hence, it significantly reduce the amount of computer memory needed to store the metadata. However, when MDQ is out of service, the Identity Provider or Service Provider will not be able to query the metadata of the entities that are requested. Therefore, it is important to ensure that the MDQ is always available.

### Installation

From the login node:

1. Open the `mdq` directory inside the `manifest` folder.

   ```bash
   cd ifirexman-training/manifest/mdq
   ```

2. Edit the `mdq.fd` file and update the `ifirexman.edu` with your federation domain fqdn in lower case. After that run the following command:

   ```bash
   kubectl create cm mdq-fd --from-file=mdq.fd -n central-svcs
   ```

3. Edit the `mdq.xrd` file and update the `iFIRExMAN` with your federation short name, replace `ifirexman.edu` with your domain name, and replace the `X509Certificate` content with the content of `cert.crt` file (without the `BEGIN CERTIFICATE` and `END CERTIFICATE` statement) from the signer folder. After that run the following command:

   ```bash
   kubectl create cm mdq-xrd --from-file=mdq.xrd -n central-svcs
   ```

4. Edit the `ingress.yaml` file and update the `ifirexman.edu` with your domain name.

5. Deploy the Metadata Query.

   ```bash
   kubectl apply -f deployment.yaml -n central-svcs
   kubectl apply -f svc.yaml -n central-svcs
   kubectl apply -f ingress.yaml -n central-svcs
   ```

   Kubernetes will create a pod that will serve the metadata query. The metadata query will be accessible at ```https://mdq.ifirexman.edu/```. Of course you need to replace `ifirexman.edu` with your domain name.

## WAYF (Where Are You From) / Discovery Service

WAYF (Where Are You From) or sometimes referred as Discovery Service too is a service, usually used by a Service Provider, to guide a user to his or her Identity Provider (IdP). When the user would like to perform an authentication, the user will be redirected to the WAYF service. The WAYF service will then display a list of IdP that the user can choose from. The user will then select the IdP that he or she would like to use for the authentication. After the user has selected the IdP, the WAYF service will redirect the user to the IdP for the authentication. This tutorial will guide you how to setup a WAYF service using the [SWITCHaai's WAYF](https://www.switch.ch/aai/support/tools/wayf/) software.

### Installation

From the login node:

1. Open the `wayf` directory inside the `manifest` folder.

2. Edit the `config.php` file and replace the `ifirexman.edu` with your domain name, `iFIRExMAN` with your federation short name, and `$supportContactEmail` with your federation support email.

3. Run the following command to create a configmap of the `config.conf` file:

   ```bash
   kubectl create cm wayf-config --from-file=config.php -n central-svcs
   ```

4. Edit the `ingress.yaml` file and replace the `ds.ifirexman.edu` with your WAYF service's domain name.

5. Deploy the WAYF service.

   ```bash
   kubectl apply -f deployment.yaml -n central-svcs
   kubectl apply -f svc.yaml -n central-svcs
   kubectl apply -f ingress.yaml -n central-svcs
   ```

   Kubernetes will create a pod that will serve the WAYF service. The WAYF service will be accessible at ```https://ds.ifirexman.edu/ds/WAYF```. Of course you need to replace `ds.ifirexman.edu` with your WAYF service's domain name.
