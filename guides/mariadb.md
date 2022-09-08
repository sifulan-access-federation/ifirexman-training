# Setting Up MariaDB

For this system, we will be using MariaDB as the database for the federation core services and vikings. We will deploy the MariaDB database in the Kubernetes cluster that we just created.


## Install MariaDB

From the login node:

1. Run the following commands:
     
    ```bash
       helm repo add bitnami https://charts.bitnami.com/bitnami
       helm install mariadb bitnami/mariadb --namespace central-svcs --create-namespace --set global.storageClass=longhorn
    ```

2. The hostname for your MariaDB is: `mariadb.central-svcs.svc.cluster.local`. Take note of this as you will need it later.

## Creating a Database

From the login node:

1. Find the root password for MariaDB by running the following command:
     
    ```bash
       kubectl get secret --namespace central-svcs mariadb -o jsonpath="{.data.mariadb-root-password}" | base64 --decode
    ``` 

    Take note the output of this command as we will need it later.

2. To create a database in the mariadb instance, run the following commands:
     
    ```bash
       kubectl run mariadb-client --rm --tty -i --restart='Never' --image  docker.io/bitnami/mariadb:10.6.8-debian-11-r23 --namespace central-svcs --command -- bash
    ```
     
    Then, inside the container, run the following commands:
     
    ```bash
       mysql -u root -p
       CREATE DATABASE YOUR_DATABASE_NAME;
       CREATE USER 'YOUR_USER_NAME'@'%' IDENTIFIED BY 'YOUR_PASSWORD';
       GRANT ALL PRIVILEGES ON YOUR_DATABASE_NAME.* TO 'YOUR_USER_NAME'@'%';
       FLUSH PRIVILEGES;
       exit
    ```
    When the mariadb is asking for the root password, enter the password that you took note earlier.

    To exit the mariadb client run:
     
    ```bash
       exit
    ```