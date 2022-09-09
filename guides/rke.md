# Setting up Kubernetes Cluster

In this tutorial, we are going to setup a Kubernetes cluster by using the [Rancher Kubernetes Engine (RKE)](https://rancher.com/products/rke). RKE is a CNCF-certified Kubernetes distribution that runs entirely within Docker containers. It solves the common frustration of installation complexity with Kubernetes by removing most host dependencies and presenting a stable path for deployment, upgrades, and rollbacks. Before we start, make sure you have the following pre-flight checklist ready.

## Pre-flight checklist

Please refer to the [iFIRExMAN_APNIC54_Training_Preparation.pdf](iFIRExMAN_APNIC54_Training_Preparation.pdf) file for pre-flight checklist.

---

## Nodes preparation

### Set up passwordless login to the Kubernetes nodes

1. Login to the Login node via SSH.
2. Generate a ssh key by using the ``ssh-keygen`` command.

   ```bash
     ssh-keygen -t ecdsa
   ```

   You don't have to set a passphrase for the private key for this purpose.
3. Copy the public key to each Kubernetes node. In this tutorial, we assume that a service account/user ```ifirexman``` exists on each node.

   ```bash
     ssh-copy-id -i ~/.ssh/id_ecdsa.pub ifirexman@<kubernetes nodes ip address>
   ```

4. Try to login to each Kubernetes node by using SSH. If you are able to login to each node without having to key-in the password, then you have successfully set up passwordless login to the Kubernetes nodes.

### Set up Docker Engine

On each Kubernetes node, you need to install Docker Engine from Docker. Before you perform the steps below, you need to perform these steps as user ```root``` or as a user with ```sudo``` permission. If you choose the latter, you need to add ```sudo``` at the start of each command.

1. Remove any existing docker installation:
  
  ```bash
    yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
  ```

2. Install Docker Engine's yum repository:

  ```bash
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  ```

3. Install Docker Engine

  ```bash
    yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
  ```

4. Start the Docker Engine

  ```bash
    systemctl start docker && systemctl enable docker
    systemctl start containerd && systemctl enable containerd
  ```

5. Add service account/user access to docker service

  ```bash
    usermod -aG docker ifirexman
  ```

### Disable swap

We need to disable swap since Kubelet does not support swap yet.

```bash
  sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
  swapoff -a
```

### Stop and disable firewall

```bash
  systemctl stop firewalld
  systemctl disable firewalld
```

### Modify bridge adapter settings

1. Load ```br_netfilter``` module

  ```bash
    modprobe br_netfilter
  ```

2. Create ```/etc/sysctl.d/kubernetes.conf``` file and insert the following values:

  ```bash
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
   ```

### Disable Extra NetworkManager Config

In Rocky Linux 8, two extra services are included on the NetworkManager: nm-cloud-setup.service and nm-cloud-setup.timer. These services add a routing table that interferes with the CNI plugin’s configuration. If these services are enabled, you must disable them using the command below, and then reboot the node to restore connectivity:

```bash
  systemctl disable nm-cloud-setup.service nm-cloud-setup.timer
  reboot
```

---

## Login node preparation

### Install Several Kubernetes management tools

#### ```git```
[Git](https://git-scm.com) is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.

To install ```git``` on the login node:

```bash
yum install -y git
```

#### ```kubectl```

The Kubernetes command-line tool, [kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/), allows you to run commands against Kubernetes clusters. You can use ```kubectl``` to deploy applications, inspect and manage cluster resources, and view logs. For more information including a complete list of kubectl operations, see the ```kubectl``` [reference documentation](https://kubernetes.io/docs/reference/kubectl/).

To install ```kubectl``` on the login node:

```bash
curl -Lo kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin
```

#### ```kubectx``` and ```kubens```

```kubectx``` is a tool to switch between contexts (clusters) on kubectl faster while ```kubens``` is a tool to switch between Kubernetes namespaces (and configure them for kubectl) easily.

To install ```kubectx``` and ```kubens``` on the login node:

```bash
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
```

#### ```k9s```

K9s is a terminal-based UI to interact with your Kubernetes clusters. K9s continually watches Kubernetes for changes and offers subsequent commands to interact with your observed resources.

To install ```k9s``` on the login node:

```bash
curl -Lo k9s_Linux_x86_64.tar.gz "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_x86_64.tar.gz"
tar -C /usr/local/bin -zxf k9s_Linux_x86_64.tar.gz k9s
```

#### ```rke```

Rancher Kubernetes Engine (RKE) is a CNCF-certified Kubernetes distribution that runs entirely within Docker containers. It works on bare-metal and virtualised servers. With RKE, the installation and operation of Kubernetes are both simplified and easily automated, and they are entirely independent of the operating system and platform you’re running.

To install ```rke``` on the login node:

```bash
curl -Lo rke https://github.com/rancher/rke/releases/download/v1.3.14/rke_linux-amd64
chmod +x rke
mv rke /usr/local/bin
```

#### ```helm```

Helm helps you manage Kubernetes applications — Helm Charts help you define, install, and upgrade even the most complex Kubernetes application.

To install ```helm``` on the login node:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

--- 
### Prepare Kubernetes Cluster file

To setup a Kubernetes cluster by using ```rke```, first we need to create a ```cluster.yml``` file which consists of our Kubernetes cluster configuration from the Login node. Below is an example of a ```cluster.yml``` file which you can use for this training.

```yaml
# Cluster Nodes
nodes:
  - address: < ip address of master node 1 >
    user: ifirexman
    role: 
      - controlplane
      - etcd
    docker_socket: /var/run/docker.sock
    ssh_key_path: ~/.ssh/id_ecdsa
  - address: < ip address of master node 2 >
    user: ifirexman
    role: 
      - controlplane
      - etcd
    docker_socket: /var/run/docker.sock
    ssh_key_path: ~/.ssh/id_ecdsa
  - address: < ip address of master node 3 >
    user: ifirexman
    role: 
      - controlplane
      - etcd
    docker_socket: /var/run/docker.sock
    ssh_key_path: ~/.ssh/id_ecdsa
  - address: < ip address of worker node 1 >
    user: ifirexman
    role: 
      - worker
    docker_socket: /var/run/docker.sock
    ssh_key_path: ~/.ssh/id_ecdsa
  - address: < ip address of worker node 2 >
    user: ifirexman
    role: 
      - worker
    docker_socket: /var/run/docker.sock
    ssh_key_path: ~/.ssh/id_ecdsa
  - address: < ip address of worker node 3 >
    user: ifirexman
    role: 
      - worker
    docker_socket: /var/run/docker.sock
    ssh_key_path: ~/.ssh/id_ecdsa

# Name of the K8s Cluster
cluster_name: rancher-cluster

services:
  kube-api:
    # IP range for any services created on Kubernetes
    # This must match the service_cluster_ip_range in kube-controller
    service_cluster_ip_range: 10.43.0.0/16
    # Expose a different port range for NodePort services
    service_node_port_range: 30000-32767
    pod_security_policy: false

  kube-controller:
    # CIDR pool used to assign IP addresses to pods in the cluster
    cluster_cidr: 10.42.0.0/16
    # IP range for any services created on Kubernetes
    # This must match the service_cluster_ip_range in kube-api
    service_cluster_ip_range: 10.43.0.0/16
  
  kubelet:
    # Base domain for the cluster
    cluster_domain: cluster.local
    # IP address for the DNS service endpoint
    cluster_dns_server: 10.43.0.10
    # Fail if swap is on
    fail_swap_on: false

network:
  plugin: flannel

# Specify DNS provider (coredns or kube-dns)
dns:
  provider: coredns
  upstreamnameservers:
    - 1.1.1.1

# Kubernetes Authorization mode
# Enable RBAC
authorization:
  mode: rbac

# Specify monitoring provider (metrics-server)
monitoring:
  provider: metrics-server
```

### Provision your cluster

Run the following command from the same directory as your `cluster.yml` file:

```bash
rke up
```

### Add cluster to your context

When the cluster has been provisioned, the following files will be generated in the root directory:

- `cluster.rkestate` - the cluster state file.
- `kube_config_cluster.yml` - the kube config file.

To add the cluster to your context, copy the kube config file

```bash
mkdir -p ~/.kube
cp kube_config_cluster.yml ~/.kube/config
```

### Check your cluster

To ensure that your cluster of nodes is running and your host machine can connect to your cluster, run the following commands:

```bash
kubectl cluster-info
kubectl get nodes
```

---

## Setting Up Longhorn Storage

Longhorn is a lightweight, reliable, and powerful distributed block storage system for Kubernetes. Longhorn implements distributed block storage using containers and microservices. The storage controller and replicas themselves are orchestrated using Kubernetes. We will use Longhorn for storing persistent storage objects.

### Longhorn Node Preparation

For each __worker__ node:

1. Login to the node by using SSH
2. Create ```/var/lib/longhorn``` folder

   ```bash
   mkdir /var/lib/longhorn
   ```

3. Format the dedicated disk for data storage and mount it at the ```/var/lib/longhorn``` folder

   ```bash
   mkfs.ext4 /dev/sdb
   mount /dev/sdb /var/lib/longhorn
   ```

   In the above example, it is assumed that the drive letter for the dedicated disk for data storage is ```sdb```. You can use the ```fdisk -l``` command to find the actual drive letter for your system. To make the operating system automatically mount the disk upon booting, you can add the following entry at the last line of the ```/etc/fstab``` file:

   ```bash
   /dev/sdb                /var/lib/longhorn       ext4    defaults        0 0
   ```

4. Install NFSv4 client and open-iscsi

   ```bash
   yum --setopt=tsflags=noscripts install iscsi-initiator-utils -y
   echo "InitiatorName=$(/sbin/iscsi-iname)" > /etc/iscsi/initiatorname.iscsi
   systemctl enable iscsid
   systemctl start iscsid
   modprobe iscsi_tcp
   yum install nfs-utils -y
   ```

### Install Longhorn

On the login node:

1. Install Longhorn on the Kubernetes cluster using this command:

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.3.1/deploy/longhorn.yaml
   ```

   You can use the ```k9s``` tool or ```kubectl get pods -n longhorn-system``` to monitor the status. A successfully deployed Longhorn looks something like this:

   ```bash
   NAME                                READY   STATUS    RESTARTS      AGE
   longhorn-iscsi-installation-9m8bg   1/1     Running   2 (50d ago)   50d
   longhorn-iscsi-installation-th4d6   1/1     Running   2 (50d ago)   50d
   longhorn-iscsi-installation-z67c5   1/1     Running   1 (50d ago)   50d
   longhorn-nfs-installation-8hrtv     1/1     Running   1 (50d ago)   50d
   longhorn-nfs-installation-95rzq     1/1     Running   2 (50d ago)   50d
   longhorn-nfs-installation-fcrl6     1/1     Running   2 (50d ago)   50d
   ```

2. Once the installation is complete, you can check whether the Longhorn storage class was successfully created by using the command below:

   ```bash
   kubectl get sc
   ```

   The output should be something like this:

   ```bash
   NAME                 PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
   longhorn (default)   driver.longhorn.io   Delete          Immediate           true                   49d
   ```

---

## Setting up MetalLB, NGINX Ingress, and Cert Manager

We are going to use MetalLB as the Load-Balancer for our Kubernetes cluster and configure the nginx ingress to take the IP address that connects the external network with the pods.

### Install MetalLB

On the login node:

1. Run the following command to install MetalLB:

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.5/config/manifests/metallb-native.yaml
   ```

   You can use the ```k9s``` tool or ```kubectl get pods -n metallb-system``` to monitor the status. A successfully installed MetalLB looks something like this:

   ```bash
   NAME                          READY   STATUS    RESTARTS   AGE
   controller-6b8d7594db-hkxg7   1/1     Running   0          382d
   speaker-2c467                 1/1     Running   2          382d
   speaker-46g8r                 1/1     Running   0          60d
   speaker-4vqlg                 1/1     Running   0          60d
   speaker-756k5                 1/1     Running   3          390d
   speaker-7frzw                 1/1     Running   0          382d
   speaker-98zdv                 1/1     Running   4          409d
   speaker-d5mfk                 1/1     Running   0          60d
   speaker-vnrjd                 1/1     Running   0          310d
   ```

2. Create ```IPAddressPool``` and ```L2Advertisement``` objects by creating a Kubernetes manifest file. To do so, create ```metallb-configuration.yaml``` file and insert the following manifest:

    ```yaml
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: rke-ip-pool
      namespace: metallb-system
    spec:
      addresses:
      - 192.168.1.240-192.168.1.250
    ---
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
    metadata:
      name: rke-ip-pool-l2-advertisement
      namespace: metallb-system
    spec:
      ipAddressPools:
      - rke-ip-pool
    ```

    You shall replace the IP address range ```192.168.1.240-192.168.1.250``` with your dedicated private ip as mentioned in the [iFIRExMAN_APNIC54_Training_Preparation.pdf](iFIRExMAN_APNIC54_Training_Preparation.pdf) file.

3. Apply the newly created manifest ```metallb-configuration.yaml```:

   ```bash
   kubectl apply -f metallb-configuration.yaml
   ```

### Reconfigure NGINX Ingress

We need to reconfigure NGINX Ingress to use ```LoadBalancer``` as the ServiceTypes. To do so, run the following command:

```bash
kubectl edit svc nginx-ingress-controller-nginx-ingress -n kube-system
```

Find ```type``` parameter under the ```spec``` and change its value to ```LoadBalancer```. After that you can save the manifest and check whether the MetalLB has assigned an IP address from the ```rke-ip-pool``` by using the following command:

```bash
kubectl get svc nginx-ingress-controller-nginx-ingress -n kube-system
```

You should have output something like this:

```bash
NAME                                     TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)                      AGE
nginx-ingress-controller-nginx-ingress   LoadBalancer   10.43.65.53   192.168.1.64   80:32757/TCP,443:31381/TCP   50d
```

### Install Cert-Manager

We are going to use Cert-Manager to manage X.509 certificates, particularly to obtain certificates from Let's Encrypt, for our services. cert-manager is a powerful and extensible X.509 certificate controller for Kubernetes workloads. It will obtain certificates from a variety of Issuers, both popular public Issuers as well as private Issuers, and ensure the certificates are valid and up-to-date, and will attempt to renew certificates at a configured time before expiry.

Below are the steps to install Cert-Manager and use it to obtain a certificate from Let's Encrypt:

1. Add Cert-Manager Helm repository:

   ```bash
   helm repo add jetstack https://charts.jetstack.io
   ```

2. Update your local Helm chart repository cache:

   ```bash
   helm repo update
   ```

3. Install Cert-Manager:

   ```bash
   helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.9.1   --set installCRDs=true --set 'extraArgs={--acme-http01-solver-nameservers=1.1.1.1:53\,8.8.8.8:53}'
   ```

4. Check Installation:

   ```bash
   kubectl get pods -n cert-manager
   ```

   The output should be something like this:

   ```bash
   NAME                                                     READY   STATUS    RESTARTS      AGE
   cert-manager-v1-1658198981-6dcb6dcbdb-sbncz              1/1     Running   2 (50d ago)   50d
   cert-manager-v1-1658198981-cainjector-67bf9cf97c-r5bdz   1/1     Running   4 (50d ago)   50d
   cert-manager-v1-1658198981-webhook-69fc6dbdb6-vrfvq      1/1     Running   4 (50d ago)   50d
   ```

5. Create an ACME HTTP Validator manifest file (e.g. ```letsencrypt-http-validation.yaml```):

   ```yaml
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: letsencrypt-http-staging
     namespace: cert-manager
   spec:
     acme:
       # The ACME server URL
       server: https://acme-staging-v02.api.letsencrypt.org/directory
       # Email address used for ACME registration
       email: user@example.com
       # Name of a secret used to store the ACME account private key
       privateKeySecretRef:
         name: letsencrypt-http-staging
       # Enable the HTTP-01 challenge provider
       solvers:
       # An empty 'selector' means that this solver matches all domains
       - selector: {}
         http01:
           ingress:
             class: nginx
   ---
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: letsencrypt-http-prod
     namespace: default
   spec:
     acme:
       # The ACME server URL
       server: https://acme-v02.api.letsencrypt.org/directory
       # Email address used for ACME registration
       email: user@example.com
       # Name of a secret used to store the ACME account private key
       privateKeySecretRef:
         name: letsencrypt-http-prod
       # Enable the HTTP-01 challenge provider
       solvers:
       # An empty 'selector' means that this solver matches all domains
       - selector: {}
         http01:
           ingress:
             class: nginx
   ```

   Replace ```user@example.com``` with your email address. Apply this manifest file by using the following command:

   ```bash
   kubectl apply -f letsencrypt-http-validation.yaml -n cert-manager
   ```

   You can check the result by using the following command:

   ```bash
   kubectl get clusterissuer
   ```

   The output looks something like this:

   ```bash
   NAME                  READY   AGE
   letsencrypt-http-prod      True    480d
   letsencrypt-http-staging   True    480d
   ```