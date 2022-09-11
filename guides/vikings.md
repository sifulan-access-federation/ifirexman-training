# How to deploy VIKINGS

## Pre-flight checklist
Fulfill all these items before running the script:
- [ ] Provision a Kubernetes cluster and log into your Login node.
- [ ] Prepare a remote MariaDB server.
- [ ] Prepare a Kubernetes namespace for VIKINGS.
- [ ] Prepare a public domain name for VIKINGS.
- [ ] Install pre-requisites on your Login node.
  - [ ] `git`
  - [ ] `kubectl`

## Login node preparation

### Install pre-requisites

#### `python3` and `python3-pip`
```sh
sudo yum install -y python3 python3-pip
```

### Clone the VIKINGS iFIRExMAN Template repository
```sh
# git clone https://github.com/sifulan-access-federation/vikings-ifirexman-template.git MY_REPO_NAME
git clone https://github.com/sifulan-access-federation/vikings-ifirexman-template.git ifirexman-vikings-client
```

### Replace deployment logo (optional)
If you wish to update or replace your deployment's logo, you will need to replace it yourself before running the script.
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

### Install required pip packages
```sh
pip3 install -r requirements.txt
```

### Run the script
```sh
./kuborc
```

### Requirements check
If all requirements have been fulfilled, submit `1`.

### Namespace check
If you are currently in the correct namespace, submit `1`. Else, submit `2` and provide the correct namespace designated for your VIKINGS deployment.

### Operation selection
Submit `1` ("Prep") to prepare your deployment manifests.

### Prep operation
Submit `2` ("Prep and deploy") to deploy your newly prepared manifests immediately after.

### VIKINGS Host
This will be used in your deployment and as a means to identify your manifests. Please enter the public domain you have prepared for VIKINGS.

### Prepare new config
The following list are all the field values you are required to provide for a VIKINGS deployment:
- `DB_NAME` - A database will be created for your VIKINGS deployment on your Remote MariaDB server using this name. Recommended name: `SHORT_ORG_NAME-vikings-maria-db`.
- `DB_USER` - Root user of your remote database.
- `DB_PASS` - Root user password of your remote database.
- `SUPPORT_EMAIL` - Support email address displayed by the Apache webserver in cases of error. Provide a support email address you can be reached from.

### Verify new config
Once you have provided all the required values for each field, you will be prompted to check and verify the config you have prepared. Submit `1` to confirm and deploy VIKINGS.

## Notes
- The username of the default VIKINGS Administrator is the `BRAND_NAME` (more commonly known as `SHORT_ORG_NAME`) of the deployment (acquired from `HOST`).
- eg. `HOST`=`vikings.sifulan.my` -> `BRAND_NAME`=`vikings`.
- The password of the default VIKINGS Administrator is `ifirexman`.