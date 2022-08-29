# How to deploy VIKINGS

## Resources
[vikings-ifirexman-template](https://github.com/sifulan-access-federation/vikings-ifirexman-template)

## Pre-flight checklist
Fulfill all these items before running the script:
- [ ] Install all required packages and libraries.
  - [ ] kubectl.
  - [ ] passlib (pip).
- [ ] Prepare a dedicated host for VIKINGS.
- [ ] Prepare a remote SQL database for VIKINGS (recommended: PostgreSQL or MariaDB).
- [ ] [Replace binary files](#replace-binary-files) under `template/binaries` according to your institution.

### Replace binary files
If you wish to update or replace some binaries such as your deployment's logo, background, or css, you will need to replace them yourself before prepping your manifests or deploying your created manifests. Their file names and formats should be retained.
- `template/binaries/vikings-logo.png`
  - Logo of your institution. Defaults to the SIFULAN logo.
- `template/binaries/vikings-background.jpg`
  - Background of your institution's VIKINGS portal. Defaults to an image of the Titiwangsa Lake Gardens, Kuala Lumpur.
- `template/binaries/vikings-favicon.ico`
  - Favicon version of your institution's logo. Defaults to the SIFULAN logo.
- `template/binaries/vikings-main.css`
  - Your institution's VIKINGS portal's css. Find and replace the colour palette accordingly. Defaults to SIFULAN blue accents.

## Walkthrough

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
* Remote SQL database
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

```py
# vikings
Field('VIKINGS_APP_NAME', 'VIKINGS Site Name', required=True, default='VIKINGS'),
Field('DEFAULT_USER_PASS', 'VIKINGS Administrator Password', required=True, secret=True, immutable=True),
Field('DB_HOST', 'Existing Database Host', required=True, immutable=True, default='cs-prod-postgres-svc.central-svcs.svc.cluster.local'),
Field('DB_TYPE', 'Database Type', required=True, immutable=True, default='postgresql'),
Field('DB_NAME', 'Database Name', required=True, immutable=True, default='$-vikings-postgres-db'),
Field('DB_USER', 'Existing Database User', required=True, immutable=True, secret=True, default='admin'),
Field('DB_PASS', 'Database Password', required=True, secret=True, immutable=True),
Field('DEBUG', 'Django Debug Mode', required=True, default='False'),
Field('SECRET_KEY', 'Django Secret Key', special=True, immutable=True, secret=True, ignore=True),
# generic
Field('SUPPORT_EMAIL', 'Support Email Address', required=True, default='ifirexman@sifulan.my'),
Field('STORAGE_CLASS', 'PVC Storage Class', required=True, immutable=True, default='freenas-nfs-csi'),
Field('STORAGE_SIZE', 'PVC Storage Size', required=True, default='50Mi'),
# additional
Field('NAMESPACE', 'Kubernetes Namespace', hidden=False),
Field('HOST', 'Application Host', hidden=False),
Field('BRAND_NAME', 'Brand Name', hidden=True),
Field('MANIFEST_PATH', 'Manifest Path', hidden=True),
Field('HOST_EMAIL', 'Host Email', hidden=True),
Field('HOST_LDAP', 'Host LDAP', hidden=True),
```

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
- The username of the Default User is the `{{ BRAND_NAME }}` of the deployment (acquired from `{{ HOST }}`).
- eg. `{{ HOST }}`=`vikings.sifulan.my` -> `{{ BRAND_NAME }}`=`vikings`.
- The password of the Default User is the password passed as `{{ DEFAULT_USER_PASS }}`.
