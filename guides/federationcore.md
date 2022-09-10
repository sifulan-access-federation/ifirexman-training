# Setting Up Federation Core Services

## Jagger

Jagger is a federation management tool developed by HEAnet to manage the Edugate multiparty SAML federation. Other organisations use Jagger to manage their federations but it can be used to manage the web-of-trust for a single entity.

### Installation

From the login node:

1. Create a database for Jagger at MariaDB. You can refer at [MariaDB](guides/mariadb.md) guide for more information. Take note of the database name, username and password which will be used in the next step.
2. Clone the [ifirexman-training](https://github.com/sifulan-access-federation/ifirexman-training) repository.

   ```bash
   git clone https://github.com/sifulan-access-federation/ifirexman-training.git
   ```

3. Open the `jagger` directory inside the `manifest` folder.

   ```bash
   cd ifirexman-training/manifest/jagger
   ```

4. Edit the `database.php` file and replace the database hostname, name, username and password with the ones you created in step 1.
5. Edit the `config_rr.php` file and update the `$config['syncpass']`, `$config['support_mailto']`, `$config['registrationAutority']` variables.
6. Edit the `config.php` file and update the `$config['encryption_key']` variable.
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

11. Edit the `ingress.yaml` file and update the `host` and `hosts` variables. Defaults to `fedmanager.domain.com`.
12. Create an ingress for Jagger.

    ```bash
    kubectl apply -f ingress.yaml -n central-svcs
    ```

13. By using `k9s` tool, login to Jagger pod.
14. Go to `/opt/jagger/application` folder and run the following commands:

    ```bash
    ./doctrine orm:schema-tool:create
    ./doctrine orm:generate-proxies
    ```

15. Verify owner of `/opt/jagger/application/models/Proxies/*` folder - `www-data` user should be owner
16. Open your web browser and go to Jagger URL (e.g. `https://fedmanager.domain.com/rr3/setup`) and fill in the form.
17. Edit file `deployment.yaml` and set `RR_SETUP_ALLOWED` to `FALSE`.
18. Run the following command to update the deployment:

    ```bash
    kubectl apply -f deployment.yaml -n central-svcs
    ```


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
   openssl req -x509 -newkey rsa:4096 -keyout cert_unencrypted.key -out cert.crt -days 3650 -nodes
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
   Country Name (2 letter code) []:MY
   State or Province Name (full name) []:
   Locality Name (eg, city) []:
   Organization Name (eg, company) []:SIFULAN Malaysian Access Federation
   Organizational Unit Name (eg, section) []:
   Common Name (eg, fully qualified host name) []:Metadata Signer
   Email Address []:
   ```

   OpenSSL will then generate a certificate and private key. You can use the following command to verify the certificate:

   ```bash
   openssl x509 -in cert.crt -text -noout
   ```

   You need to create a copy of the private key that we just created and set it with a passphrase. You can use the following command:

   ```bash
   openssl rsa -aes256 -in cert_unencrypted.key -out cert.key
   ```

   When running this command, openssl will ask you to enter a passphrase. You can enter any passphrase that you want. You will need to enter the passphrase when you configure the Metadata Signer.

   Now, let's validate all the keys that we just created:

   ```bash
   openssl rsa -in cert.key -modulus -noout
   openssl rsa -in cert_unencrypted.key -modulus -noout
   openssl x509 -in cert.crt -modulus -noout
   ```

   Make sure that all the modulus values are the same.

3. Create a secret for the Metadata Signer.

   ```bash
   kubectl create secret generic signer-config --from-file=cert.crt --from-file=cert_unencrypted.key --from-file=cert.key -n central-svcs
   kubectl create secret generic metadata-signer-keypassword --from-literal=password=YOUR_PRIVATE_KEY_PASSPHRASE -n central-svcs
   ```

   Replace `YOUR_PRIVATE_KEY_PASSPHRASE` with the passphrase that you entered when you created the private key.

4. Edit the `update.sh` file and update the `FEDERATION` with your federation name set at Jagger. After that run the following command:

   ```bash
   kubectl create cm metadata-signer-update-sh --from-file=update.sh -n central-svcs
   kubectl create cm metadata-signer-sign-sh --from-file=sign.sh -n central-svcs
   ```

5. Edit the `edugain.fd` file and update the `domain.com` with your federation's registration authority name and `federation` with your federation name set at Jagger. After that run the following command:

   ```bash
   kubectl create cm metadata-signer-edugain-fd --from-file=edugain.fd -n central-svcs
   kubectl create cm metadata-signer-edugain-ca --from-file=eduGAIN-signer-ca.pem -n central-svcs
   ```

6. Edit the `full.fd` file and update the `FEDERATION` and `federation` with your federation name set at Jagger. After that run the following command:

   ```bash
   kubectl create cm metadata-signer-full-fd --from-file=full.fd -n central-svcs
   ```

7. Deploy the Metadata Signer.

   ```bash
   kubectl apply -f cron.yaml -n central-svcs
   ```

   Kuebernetes will create a job that will periodically (every 1 hour) download the metadata from Jagger and sign it. The signed metadata will be accessible at ```https://fedmanager.domain.com/metadata.xml```, ```https://federation.domain.com/edugain-export-metadata.xml```, and ```https://fedmanager.domain.com/full-metadata.xml```. Of course you need to replace `domain.com` with your domain name.

## Metadata Query

The Metadata Query (MDQ) is a web service that can be used to query the metadata (on-demand) of a Federation operator. In comparison with the traditional method to download the full set of metadata file from the Federation operator, the MDQ allows Identity Provider or Service Provider to query the metadata of the entities that are requested only from the Federation operator. Hence, it significantly reduce the amount of computer memory needed to store the metadata. However, when MDQ is out of service, the Identity Provider or Service Provider will not be able to query the metadata of the entities that are requested. Therefore, it is important to ensure that the MDQ is always available.

### Installation

From the login node:

1. Open the `mdq` directory inside the `manifest` folder.

   ```bash
   cd ifirexman-training/manifest/mdq
   ```

2. Edit the `mdq.fd` file and update the `federation` with your federation name. After that run the following command:

   ```bash
   kubectl create cm mdq-fd --from-file=mdq.fd -n central-svcs
   ```

3. Edit the `mdq.xrd` file and update the `FEDERATION` with your federation name, replace `domain.com` with your domain name, and replace the `X509Certificate` with the content of `cert.crt` file (without the `BEGIN CERTIFICATE` and `END CERTIFICATE` statement) from the signer folder. After that run the following command:

   ```bash
   kubectl create cm mdq-xrd --from-file=mdq.xrd -n central-svcs
   ```

4. Deploy the Metadata Query.

   ```bash
   kubectl apply -f deployment.yaml -n central-svcs
   kubectl apply -f svc.yaml -n central-svcs
   kubectl apply -f ingress.yaml -n central-svcs
   ```

   Kubernetes will create a pod that will serve the metadata query. The metadata query will be accessible at ```https://mdq.domain.com/```. Of course you need to replace `domain.com` with your domain name.