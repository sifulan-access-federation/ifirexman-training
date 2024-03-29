# How to deploy VIKINGS

## Overview

This tutorial provides step-by-step instructions on how to setup VIKINGS as an IdP's Identity Management System (IDMS) solution.

You are only required to follow this tutorial if you intend on using VIKINGS as the backend authenticator for an IdP.

## Pre-flight checklist
Fulfill all these items before running the script:
- [ ] Provision a Kubernetes cluster and log into your Login node.
- [ ] Prepare a remote MariaDB server.
- [ ] Prepare a public domain name for VIKINGS.
- [ ] Install pre-requisites on your Login node.
  - [ ] `git`
  - [ ] `kubectl`

## Login node preparation

### Create VIKINGS database
Create a database for VIKINGS on MariaDB. You can refer to the [MariaDB](guides/mariadb.md) guide for more information. Take note of the database name, username and password which will be used later when deploying VIKINGS.

### Prepare a Kubernetes namespace
Create a Kubernetes namespace dedicated to VIKINGS.
```sh
kubectl create ns vikings
```

Enter the created namespace.
```sh
kubens vikings
```

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
- `DB_NAME` - Name of the database created for VIKINGS on MariaDB.
- `DB_USER` - User of the database.
- `DB_PASS` - User password of the database user.
- `SUPPORT_EMAIL` - Support email address displayed by the Apache webserver in cases of error. Provide a support email address you can be reached from.

### Verify new config
Once you have provided all the required values for each field, you will be prompted to check and verify the config you have prepared. Submit `1` to confirm and deploy VIKINGS.

## Notes
- The username of the default VIKINGS Administrator is the `BRAND_NAME` (more commonly known as `SHORT_ORG_NAME`) of the deployment (acquired from `HOST`).
- eg. `HOST`=`vikings.sifulan.my` -> `BRAND_NAME`=`vikings`.
- The password of the default VIKINGS Administrator is `ifirexman`.