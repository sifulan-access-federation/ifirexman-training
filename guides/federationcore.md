# Setting Up Federation Core Services

## Prep

From the login node:

1. Create a namespace for federation core services:

    ```bash
    kubectl create namespace federation
    ```

## Jagger

Jagger is a federation management tool developed by HEAnet to manage the Edugate multiparty SAML federation. Other organisations use Jagger to manage their federations but it can be used to manage the web-of-trust for a single entity.

### Installation

From the login node:

1. Create a mysql database for Jagger. The database name, username and password will be used in the next step.
2. Open the `jagger` directory inside the `manifest` folder.

   ```bash
   cd ifirexman-training/manifest/jagger
   ```

3. Edit the `database.php` file and replace the database name, username and password with the ones you created in step 1.
4. Edit the `config_rr.php` file and update the `$config['syncpass']`, `$config['support_mailto']`, `$config['registrationAutority']` variables.
5. Edit the `config.php` file and update the `$config['encryption_key']` variable.
6. Edit the `email.php` file and update the `$config['smtp_host']`, `$config['smtp_user']`, `$config['smtp_pass']` variables.
7. Create a secret for Jagger.

   ```bash
   kubectl create secret generic jagger-config --from-file=database.php --from-file=config_rr.php --from-file=config.php --from-file=email.php --from-file=memcached.php -n federation
   ```

8. Deploy Jagger.

   ```bash
   kubectl apply -f deployment.yaml -n federation
   ```

9. Create a service for Jagger.

   ```bash
   kubectl apply -f svc.yaml -n federation
   ```

10. Edit the `ingress.yaml` file and update the `host` variable.
11. Create an ingress for Jagger.

    ```bash
    kubectl apply -f ingress.yaml -n federation
    ```

12. By using `k9` tool, login to Jagger pod.
13. Edit file `/opt/jagger/application/config/config_rr.php` and set `$config['rr_setup_allowed']` to `TRUE`.
14. Go to `/opt/jagger/application` folder and run the following commands:
    ```bash
    ./doctrine orm:schema-tool:create
    ./doctrine orm:generate-proxies
    ```
15. Verify owner of `/opt/jagger/application/models/Proxies/*` folder - `www-data` user should be owner
16. Open your web browser and go to Jagger URL (e.g. `https://fedmanager.domain.com/setup`) and fill in the form.
17. Back to the Jagger pod, edit file `/opt/jagger/application/config/config_rr.php` and set `$config['rr_setup_allowed']` to `FALSE`.
