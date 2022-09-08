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
If all requirements have been fulfilled, submit `1`.

### Namespace check
If you are currently in the `central-svcs` namespace, submit `1`. Else, submit `2` and enter `central-svcs` as the namespace.

### Operation selection
Submit `1` ("Prep") to prepare your deployment manifests.

### Prep operation
Submit `2` ("Prep and deploy") to deploy your newly prepared manifests immediately after.

### MariaDB Host
This will be used in your deployment and as a means to identify your manifests. You are **required** to enter `cs-prod.mariadb.local` as the Host.

### Prepare new config for your manifests
The following list are all the field values you are required to provide for a MariaDB deployment:
- `DB_USER` - Root user of your database. Defaults to "root".
- `DB_PASS` - User password of your root user.
- `BACKUP_USER` - Backup user of your database. Defaults to "mariabackup".
- `BACKUP_PASS` - User password of your backup user.

### Verify new config
Once you have provided all the required values for each field, you will be prompted to check and verify the config you have prepared. Submit `1` to confirm and deploy your MariaDB server.