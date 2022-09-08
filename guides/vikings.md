# How to deploy VIKINGS

## Pre-flight checklist
Fulfill all these items before running the script:
- [ ] Provision a Kubernetes cluster and log into your Login node.
- [ ] Prepare a remote MariaDB database for VIKINGS.
- [ ] Prepare a Kubernetes namespace for VIKINGS.
- [ ] Prepare a dedicated domain name for VIKINGS.
- [ ] Install pre-requisites on your Login node.
  - [ ] `git`
  - [ ] `kubectl`
  - [ ] `python3`
  - [ ] `python3-pip`
  - [ ] `passlib`

## Login node preparation

### Clone the VIKINGS iFIRExMAN Template repository
```sh
# git clone https://github.com/sifulan-access-federation/vikings-ifirexman-template.git MY_REPO_NAME
git clone https://github.com/sifulan-access-federation/vikings-ifirexman-template.git ifirexman-vikings-client
```

### Replace binary files (optional)
If you wish to update or replace your deployment's logo, you will need to replace it yourself before running the script. Its file name and format should be retained.
- `MY_REPO_LOCATION/template/binaries/vikings-logo.png` - Logo of your institution. Defaults to the iFIRExMAN logo.

```sh
# cp MY_ORG_LOGO.png MY_REPO_LOCATION/template/binaries/vikings-logo.png
cp MY_ORG_LOGO.png ~/ifirexman-vikings-client/template/binaries/vikings-logo.png
```

## Walkthrough

### Get into your repository
```sh
# cd MY_REPO_LOCATION
cd ~/ifirexman-vikings-client
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
* Remote MariaDB database
1 - Yes
2 - No
Please select an option [1-2]:
```

If all requirements have been fulfilled, submit `1`.

### Namespace check
```sh
#==========NAMESPACE==========#
Current namespace: vikings
1 - Yes
2 - No
Please select an option [1-2]:
```

If you are currently in the correct namespace, submit `1`. Else, submit `2` and provide the correct namespace.

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
- Select "Deploy" to deploy your specified institution's existing manifests (in the `file` folder).
- Select "Update" to redeploy your institution's existing deployments (destroys everything but existing persistent storage and redeploy).
- Select "Destroy" to destroy everything including manifests and keep a backup of the institution's existing config.

### Prep operation
```sh
#==========PREP OPERATION==========#
1 - Prep only
2 - Prep and deploy
3 - Prep and update
Please select an option [1-3]:
```

If "Prep" was selected, an additional selection must be made:
- Select "Prep only" by submitting `1` if you intend to only prepare manifests for your institution.
- Select "Prep and deploy" to prepare your manifests and deploy them immediately after.
- Select "Prep and update" to prepare your manifests and update existing deployments (eg. destroy and deploy while retaining existing persistent storage).

### VIKINGS Host
Regardless of the selected operation, you will be required to provide a host URL for VIKINGS. This URL will be used in your deployment, as well as to identify your manifests. This Host URL will also be used to determine the values of certain variables, not limited to those shown in the following example:

```sh
#==========VIKINGS HOST==========#
Vikings Host URL [vikings.com]: testbed.vikings.e-id.my
CONFIG_FILE=config/.config-testbed-devel
BRAND_NAME=testbed
MANIFEST_PATH=file/testbed-devel
```

### Prepare new config
If "Prep" was part of your operation selection, you will be guided to prepare a new config that will be used for your deployments. During this process, you will be prompted for values for all the fields configured in `setup.py`. Depending on how the field was configured, the field may be:
- `required` and fail the process if no value is provided.
- `default` value to fallback should no value is provided by the user.
- `secret` which will encode the value in base64 when placed in your manifests.
- `immutable` and cannot be configured during an "Update" session, instead relying on its value from an existing config if available.
- `special` where the field has a specific way of handling configured in the `handle_special_fields` method found in `utils.py`.
- `ignore` which flags the field to be ignored and requires no input from the user for its value (often paired with `special=True` for special fields' dependencies).
- `hidden` fields and their values are omitted from the "Verify new config" session, but can still be found in the completed config file.

The following list are all the fields required and configured for a *lite* VIKINGS deployment:

#### `DB_NAME`
```py
Field('DB_NAME', 'VIKINGS Database Name', required=True, immutable=True, default='X-vikings-maria-db'),
```
- A database will be created for your VIKINGS deployment on your Remote MariaDB server using this name.
- Recommended name: `SHORT_ORG_NAME-vikings-maria-db`

#### `DB_USER`
```py
Field('DB_USER', 'Remote Database User', required=True, immutable=True, secret=True, default='root'),
```
- Root user of your remote database.

#### `DB_PASS`
```py
Field('DB_PASS', 'Remote Database Password', required=True, secret=True, immutable=True),
```
- Root user password of your remote database.

#### `SUPPORT_EMAIL`
```py
Field('SUPPORT_EMAIL', 'Support Email Address', required=True, default='support@domain.org'),
```
- Support email address displayed by the Apache webserver in cases of error. Provide a support email address you can be reached from.

### Verify new config
```sh
#==========VERIFY NEW CONFIG==========#
NAMESPACE : devel
HOST : testbed.vikings.e-id.my
...
STUDENT_REALM : UNAVAILABLE
1 - Yes
2 - No
Please select an option [1-2]:
```

- Once you have provided all the required values for each field, you will be prompted to check and verify the config you have prepared.
- If `1` is selected, manifests specific to your institution will be prepared according to the new config and the script will then carry on.
- If "Prep and deploy" was selected, your manifests will be deployed after.
- Likewise, if "Prep and update" was selected, your existing deployments will be updated according to the newly prepared config.

### Existing config
If "Prep" was not part of your operation selection, the script will instead proceed to look for an existing config and manifest of your institution according to your input in [VIKINGS host](#vikings-host). If this was found, you will be prompted to confirm the existing config of your institution.

```sh
#==========EXISTING CONFIG==========#
NAMESPACE : devel
HOST : testbed.vikings.e-id.my
...
STUDENT_REALM : UNAVAILABLE
1 - Yes
2 - No
Please select an option [1-2]:
```

If `1` is submitted, the script will continue to carry out your chosen operation.


## Notes
- The username of the default VIKINGS Administrator is the `BRAND_NAME` (more commonly known as `SHORT_ORG_NAME`) of the deployment (acquired from `HOST`).
- eg. `HOST`=`vikings.sifulan.my` -> `BRAND_NAME`=`vikings`.
- The password of the default VIKINGS Administrator is `ifirexman`.
