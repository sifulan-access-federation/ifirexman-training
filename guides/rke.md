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
    yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
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

In Rocky Linux 8, two extra services are included on the NetworkManager: nm-cloud-setup.service and nm-cloud-setup.timer. These services add a routing table that interferes with the CNI plugin???s configuration. If these services are enabled, you must disable them using the command below, and then reboot the node to restore connectivity:

```bash
  systemctl disable nm-cloud-setup.service nm-cloud-setup.timer
  reboot
```

---

## Login node preparation

### Install Several Kubernetes management tools

#### ```docker```
Follow the same steps used in the [Set up Docker Engine](#set-up-docker-engine) section to install Docker on the login node.

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

Rancher Kubernetes Engine (RKE) is a CNCF-certified Kubernetes distribution that runs entirely within Docker containers. It works on bare-metal and virtualised servers. With RKE, the installation and operation of Kubernetes are both simplified and easily automated, and they are entirely independent of the operating system and platform you???re running.

To install ```rke``` on the login node:

```bash
curl -Lo rke https://github.com/rancher/rke/releases/download/v1.3.14/rke_linux-amd64
chmod +x rke
mv rke /usr/local/bin
```

#### ```helm```

Helm helps you manage Kubernetes applications ??? Helm Charts help you define, install, and upgrade even the most complex Kubernetes application.

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
    - <change to your local dns server's ip address>

# Kubernetes Authorization mode
# Enable RBAC
authorization:
  mode: rbac

# Specify monitoring provider (metrics-server)
monitoring:
  provider: metrics-server

# Disable ingress controller
ingress:
  provider: none
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
   kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.3.1/deploy/prerequisite/longhorn-iscsi-installation.yaml
   kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.3.1/deploy/prerequisite/longhorn-nfs-installation.yaml
   ```

5. After the deployment, run the following command to check pods??? status of the installer:

   ```bash
   kubectl get pod | grep longhorn-iscsi-installation
   kubectl get pod | grep longhorn-nfs-installation
   ```

   The output should be similar to the following:

   ```bash
   longhorn-iscsi-installation-7k9m6   1/1     Running    0          47s
   longhorn-iscsi-installation-dfhxc   1/1     Running    0          47s
   longhorn-iscsi-installation-xqvdp   1/1     Running    0          47s
   ```

    ```bash
    longhorn-nfs-installation-2l9sp     1/1     Running   0          111s
    longhorn-nfs-installation-n2zp8     1/1     Running   0          111s
    longhorn-nfs-installation-sgwd5     1/1     Running   0          111s
    ```

    And also can check the log with the following command to see the installation result:

    ```bash
    kubectl logs longhorn-iscsi-installation-7k9m6 -c iscsi-installation
    ```

    ```bash
    kubectl logs longhorn-nfs-installation-2l9sp -c nfs-installation
    ```

    The output should be similar to the following:

    ```bash
    Installed:
    iscsi-initiator-utils-6.2.1.4-4.git095f59c.el8.x86_64                         
    iscsi-initiator-utils-iscsiuio-6.2.1.4-4.git095f59c.el8.x86_64                
    isns-utils-libs-0.99-1.el8.x86_64                                             

    iscsi install successfully
    ```

    ```bash
    Installed:
    gssproxy-0.8.0-20.el8.x86_64              keyutils-1.5.10-9.el8.x86_64        
    libverto-libevent-0.3.0-5.el8.x86_64      nfs-utils-1:2.3.3-51.el8.x86_64     
    python3-pyyaml-3.12-12.el8.x86_64         quota-1:4.04-14.el8.x86_64          
    quota-nls-1:4.04-14.el8.noarch            rpcbind-1.2.5-8.el8.x86_64          

    nfs install successfully
    ```

6. Run the following command to ensure that the nodes have all the necessary to install longhorn:

   ```bash
   curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.3.1/scripts/environment_check.sh | bash
   ```

   The output should be similar to the following:

   ```bash
   [INFO]  Required dependencies are installed.
   [INFO]  Waiting for longhorn-environment-check pods to become ready (0/3)...
   [INFO]  All longhorn-environment-check pods are ready (3/3).
   [INFO]  Required packages are installed.
   [INFO]  Cleaning up longhorn-environment-check pods...
   [INFO]  Cleanup completed.
    ```

   Note: `jq` maybe required to be installed locally prior to running env check script. To install `jq` on Rocky Linux, run the following command:

   ```bash
   yum install -y jq
   ```

### Install Longhorn

On the login node:

1. Install Longhorn on the Kubernetes cluster using this command:

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.3.1/deploy/longhorn.yaml
   ```

   You can use the ```k9s``` tool or ```kubectl get pods -n longhorn-system``` to monitor the status. A successfully deployed Longhorn looks something like this:

   ```bash
   NAME                                           READY   STATUS    RESTARTS   AGE
   csi-attacher-dcb85d774-d6ct2                   1/1     Running   0          7m16s
   csi-attacher-dcb85d774-f4qjb                   1/1     Running   0          7m16s
   csi-attacher-dcb85d774-vpjzv                   1/1     Running   0          7m16s
   csi-provisioner-5d8dd96b57-2ww7k               1/1     Running   0          7m16s
   csi-provisioner-5d8dd96b57-g58ts               1/1     Running   0          7m16s
   csi-provisioner-5d8dd96b57-x49gc               1/1     Running   0          7m16s
   csi-resizer-7c5bb5fd65-hvt59                   1/1     Running   0          7m16s
   csi-resizer-7c5bb5fd65-stmtd                   1/1     Running   0          7m16s
   csi-resizer-7c5bb5fd65-tj7tj                   1/1     Running   0          7m16s
   csi-snapshotter-5586bc7c79-869zp               1/1     Running   0          7m15s
   csi-snapshotter-5586bc7c79-rqxpp               1/1     Running   0          7m15s
   csi-snapshotter-5586bc7c79-zdxs5               1/1     Running   0          7m15s
   engine-image-ei-766a591b-9nkw4                 1/1     Running   0          7m24s
   engine-image-ei-766a591b-b2f24                 1/1     Running   0          7m24s
   engine-image-ei-766a591b-xkn98                 1/1     Running   0          7m24s
   instance-manager-e-8d454591                    1/1     Running   0          7m23s
   instance-manager-e-d894e807                    1/1     Running   0          7m24s
   instance-manager-e-e5aa709b                    1/1     Running   0          7m24s
   instance-manager-r-0c0861f9                    1/1     Running   0          7m23s
   instance-manager-r-d2d51044                    1/1     Running   0          7m24s
   instance-manager-r-f6b6d7d8                    1/1     Running   0          7m24s
   longhorn-admission-webhook-858d86b96b-bmfr8    1/1     Running   0          7m54s
   longhorn-admission-webhook-858d86b96b-c8hvh    1/1     Running   0          7m54s
   longhorn-conversion-webhook-576b5c45c7-4gbrz   1/1     Running   0          7m54s
   longhorn-conversion-webhook-576b5c45c7-sz4xj   1/1     Running   0          7m54s
   longhorn-csi-plugin-dh475                      2/2     Running   0          7m15s
   longhorn-csi-plugin-dpljd                      2/2     Running   0          7m15s
   longhorn-csi-plugin-j9rzf                      2/2     Running   0          7m15s
   longhorn-driver-deployer-6687fb8b45-vhqhs      1/1     Running   0          7m54s
   longhorn-manager-4ntvh                         1/1     Running   0          7m54s
   longhorn-manager-ln4gs                         1/1     Running   0          7m54s
   longhorn-manager-lttlz                         1/1     Running   0          7m54s
   longhorn-ui-86b56b95c8-xxmc7                   1/1     Running   0          7m54s
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
   NAME                         READY   STATUS    RESTARTS   AGE
   controller-6d5cb87f6-p2rp6   1/1     Running   0          63m
   speaker-kz2l6                1/1     Running   0          63m
   speaker-pqxh6                1/1     Running   0          63m
   speaker-txd75                1/1     Running   0          63m
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

### Install NGINX Ingress

On the login node:

1. Run the following command to install NGINX Ingress:

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.1/deploy/static/provider/baremetal/deploy.yaml
   ```

   You can use the ```k9s``` tool or ```kubectl get pods -n ingress-nginx``` to monitor the status. A successfully installed NGINX Ingress looks something like this:

   ```bash
   NAME                                       READY   STATUS      RESTARTS   AGE
   ingress-nginx-admission-create-4cvm5       0/1     Completed   0          32s
   ingress-nginx-admission-patch-c5zbb        0/1     Completed   1          32s
   ingress-nginx-controller-b7b55cccc-mcsjg   0/1     Running     0          32s
   ```

2. We need to reconfigure NGINX Ingress to use ```LoadBalancer``` as the ServiceTypes. To do so, run the following command:

   ```bash
   kubectl edit svc ingress-nginx-controller -n ingress-nginx
   ```
   
   Find ```type``` parameter under the ```spec``` and change its value from ```NodePort``` to ```LoadBalancer```. After that you can save the manifest and check whether the MetalLB has assigned an IP address from the ```rke-ip-pool``` by using the following command:
   
   ```bash
   kubectl get svc ingress-nginx-controller -n ingress-nginx
   ```
   
   You should have output something like this:
   
   ```bash
   NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)                      AGE
   ingress-nginx-controller   LoadBalancer   10.43.24.174   192.168.1.75   80:30590/TCP,443:31230/TCP   3m4s
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
   helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.9.1   --set installCRDs=true
   ```

4. Check Installation:

   ```bash
   kubectl get pods -n cert-manager
   ```

   The output should be something like this:

   ```bash
   NAME                                      READY   STATUS    RESTARTS   AGE
   cert-manager-877fd747c-rffcd              1/1     Running   0          24s
   cert-manager-cainjector-bbdb88874-788wh   1/1     Running   0          24s
   cert-manager-webhook-5774d5d8f7-vc8jr     1/1     Running   0          24s
   ```

5. Run the following command to add an additional ```dnsConfig``` options at the ```cert-manager``` deployment:

   ```bash
   kubectl edit deployment cert-manager -n cert-manager
   ```

   Add the following lines under the `dnsPolicy: ClusterFirst` line:

   ```yaml
   dnsPolicy: ClusterFirst
   dnsConfig:
     options:
       - name: ndots
         value: "1"
   ``` 

6. Create an ACME HTTP Validator manifest file (e.g. ```letsencrypt-http-validation.yaml```):

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
             serviceType: ClusterIP
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
             serviceType: ClusterIP
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
   NAME                       READY   AGE
   letsencrypt-http-prod      True    7s
   letsencrypt-http-staging   True    7s
   ```