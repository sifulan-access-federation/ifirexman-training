# How to deploy MariaDB

## Pre-flight checklist
Fulfill all these items before running the script:
- [ ] Provision a Kubernetes cluster and log into your Login node.
- [ ] Install pre-requisites on your Login node.
  - [ ] `git`
  - [ ] `kubectl`

## Login node preparation

### Install pre-requisites

#### `python3` and `python3-pip`
```sh
sudo yum install -y python3 python3-pip
```

#### `passlib`
```sh
pip3 install passlib==1.7.4
```

### Create a Kubernetes namespace named `central-svcs`
```sh
kubectl create ns central-svcs
```

### Clone the MariaDB iFIRExMAN Template repository
```sh
# git clone https://github.com/sifulan-access-federation/mariadb-ifirexman-template.git MY_REPO_NAME
git clone https://github.com/sifulan-access-federation/mariadb-ifirexman-template.git ifirexman-mariadb-client
```

## Walkthrough

### Get into your repository
```sh
# cd MY_REPO_LOCATION
cd ~/ifirexman-mariadb-client
```

### Run the script
```sh
./kuborc
```

### Requirements check
```sh
#==========REQUIREMENTS==========#
The following requirements are required to use this script:
* kubectl
* passlib (pip)
* Host domain
* Existing config file (if applicable)
* Existing manifest (if applicable)
1 - Yes
2 - No
Please select an option [1-2]:
```

If all requirements have been fulfilled, submit `1`.

### Namespace check
```sh
#==========NAMESPACE==========#
Current namespace: central-svcs
1 - Yes
2 - No
Please select an option [1-2]:
```

If you are currently in the `central-svcs` namespace, submit `1`. Else, submit `2` and enter `central-svcs` as the namespace.

### Operation selection
```sh
#==========OPERATION==========#
1 - Prep [...]
2 - Deploy
3 - Update
4 - Destroy
Please select an option [1-4]:
```

- Select "Prep" by submitting `1` if your desired operation involves creating or updating your manifests.
- Select "Deploy" to deploy your specified host's existing manifests (in the `file` folder).
- Select "Update" to redeploy your host's existing deployments (destroys everything but existing persistent storage and redeploy).
- Select "Destroy" to destroy everything including manifests and keep a backup of the host's existing config.

### Prep operation
```sh
#==========PREP OPERATION==========#
1 - Prep only
2 - Prep and deploy
3 - Prep and update
Please select an option [1-3]:
```

If "Prep" was selected, an additional selection must be made:
- Select "Prep only" by submitting `1` if you intend to only prepare manifests for your host.
- Select "Prep and deploy" to prepare your manifests and deploy them immediately after.
- Select "Prep and update" to prepare your manifests and update existing deployments (eg. destroy and deploy while retaining existing persistent storage).

### MariaDB Host
Regardless of the selected operation, you will be required to provide a host URL for MariaDB. This URL will be used in your deployment and as a means to identify your manifests. This Host URL will also be used to determine the values of certain variables, not limited to those shown in the following example:

```sh
#==========MARIADB HOST==========#
Mariadb Host URL [mariadb.com]: cs-prod.mariadb.local
CONFIG_FILE=config/.config-cs-prod-central-svcs
BRAND_NAME=cs-prod
MANIFEST_PATH=file/cs-prod-central-svcs
```

In this section, you are **required** to enter `cs-prod.mariadb.local` as the Host URL.

### Prepare new config
If "Prep" was part of your operation selection, you will be guided to prepare a new config that will be used for your deployments. During this process, you will be prompted for values for all the fields configured in `setup.py`. Depending on how the field was configured, the field may be:
- `required` and fail the process if no value is provided.
- `default` value to fallback should no value is provided by the user.
- `secret` which will encode the value in base64 when placed in your manifests.
- `immutable` and cannot be configured during an "Update" session, instead relying on its value from an existing config if available.
- `special` where the field has a specific way of handling configured in the `handle_special_fields` method found in `utils.py`.
- `ignore` which flags the field to be ignored and requires no input from the user for its value (often paired with `special=True` for special fields' dependencies).
- `hidden` fields and their values are omitted from the "Verify new config" session, but can still be found in the completed config file.

The following list are all the fields required and configured for a MariaDB deployment:

#### `DB_USER`
```py
Field('DB_USER','Database User',required=True,immutable=True,secret=True,default='root'),
```
- Root user of your database. Defaults to "root".

#### `DB_PASS`
```py
Field('DB_PASS','Database Password',required=True,immutable=True,secret=True),
```
- User password of your root user.

#### `BACKUP_USER`
```py
Field('BACKUP_USER','Backup Database User',required=True,immutable=True,secret=True,default='mariabackup'),
```
- Backup user of your database. Defaults to "mariabackup".

#### `BACKUP_PASS`
```py
Field('BACKUP_PASS','Backup Database Password',required=True,immutable=True,secret=True),
```
- User password of your backup user.

### Verify new config
```sh
#==========VERIFY NEW CONFIG==========#
NAMESPACE : central-svcs
HOST : cs-prod.mariadb.local
...
BACKUP_PASS : XXX
1 - Yes
2 - No
Please select an option [1-2]:
```

- Once you have provided all the required values for each field, you will be prompted to check and verify the config you have prepared.
- If `1` is selected, manifests specific to your host will be prepared according to the new config and the script will then carry on.
- If "Prep and deploy" was selected, your manifests will be deployed after.
- Likewise, if "Prep and update" was selected, your existing deployments will be updated according to the newly prepared config.

### Existing config
If "Prep" was not part of your operation selection, the script will instead proceed to look for an existing config and manifest of your institution according to your input in [MariaDB host](#mariadb-host). If this was found, you will be prompted to confirm the existing config of your host.

```sh
#==========EXISTING CONFIG==========#
NAMESPACE : central-svcs
HOST : cs-prod.mariadb.local
...
BACKUP_PASS : XXX
1 - Yes
2 - No
Please select an option [1-2]:
```

If `1` is submitted, the script will continue to carry out your chosen operation.
