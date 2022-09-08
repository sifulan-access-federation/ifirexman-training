# Setting Up Federation Core Services

## Jagger

Jagger is a federation management tool developed by HEAnet to manage the Edugate multiparty SAML federation. Other organisations use Jagger to manage their federations but it can be used to manage the web-of-trust for a single entity.

### Installation

From the login node:

1. Create a database for Jagger at MariaDB. You can refer at [MariaDB](guides/mariadb.md) guide for more information. Take note the database name, username and password will be used in the next step.
2. Open the `jagger` directory inside the `manifest` folder.

   ```bash
   cd ifirexman-training/manifest/jagger
   ```

3. Edit the `database.php` file and replace the database hostname, name, username and password with the ones you created in step 1.
4. Edit the `config_rr.php` file and update the `$config['syncpass']`, `$config['support_mailto']`, `$config['registrationAutority']` variables.
5. Edit the `config.php` file and update the `$config['encryption_key']` variable.
6. Edit the `email.php` file and update the `$config['smtp_host']`, `$config['smtp_user']`, `$config['smtp_pass']` variables.
7. Create a secret for Jagger.

   ```bash
   kubectl create secret generic jagger-config --from-file=database.php --from-file=config_rr.php --from-file=config.php --from-file=email.php --from-file=memcached.php -n federation
   ```
8. Create a PVC for Jagger.

   ```bash
   kubectl apply -f jagger-pvc.yaml -n central-svcs
   ```

9. Deploy Jagger.

   ```bash
   kubectl apply -f deployment.yaml -n central-svcs
   ```

10. Create a service for Jagger.

   ```bash
   kubectl apply -f svc.yaml -n central-svcs
   ```

11. Edit the `ingress.yaml` file and update the `host` variable.
12. Create an ingress for Jagger.

    ```bash
    kubectl apply -f ingress.yaml -n central-svcs
    ```

13. By using `k9s` tool, login to Jagger pod.
14. Edit file `/opt/jagger/application/config/config_rr.php` and set `$config['rr_setup_allowed']` to `TRUE`.
15. Go to `/opt/jagger/application` folder and run the following commands:

    ```bash
    ./doctrine orm:schema-tool:create
    ./doctrine orm:generate-proxies
    ```

16. Verify owner of `/opt/jagger/application/models/Proxies/*` folder - `www-data` user should be owner
17. Open your web browser and go to Jagger URL (e.g. `https://fedmanager.domain.com/rr3/setup`) and fill in the form.
18. Back to the Jagger pod, edit file `/opt/jagger/application/config/config_rr.php` and set `$config['rr_setup_allowed']` to `FALSE`.

## Metadata Signer

To ensure that the metadata feeds provided by a Federation operator is genuine, the metadata feeds are need to be digitally signed by the Federation operator. For this purpose, we will use a combination of [PyFF](https://pyff.io/) and [xmlsectool](https://shibboleth.atlassian.net/wiki/spaces/XSTJ3/overview) (for simplicity, we will call it as Metadata Signer). These tools that can be used to digitally sign metadata feeds.

The Metadata Signer will be deployed as a cronjob, which will periodically download the metadata from Jagger and sign it.
