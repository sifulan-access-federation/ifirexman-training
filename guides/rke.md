# Setting up Kubernetes Cluster

In this tutorial, we are going to setup a Kubernetes cluster by using the [Rancher Kubernetes Engine (RKE)](https://rancher.com/products/rke). RKE is a CNCF-certified Kubernetes distribution that runs entirely within Docker containers. It solves the common frustration of installation complexity with Kubernetes by removing most host dependencies and presenting a stable path for deployment, upgrades, and rollbacks. Before we start, make sure you have the following pre-flight checklist ready.

## Pre-flight checklist

- [ ] 4 VMs (CPU Cores 4, RAM 8GB, Storage 25GB, Rocky Linux release 8.6).
  - [ ] 1 Login node.
  - [ ] 3 Master nodes.
- [ ] 3 VMs (CPU Cores >=8, RAM >=16GB, OS Storage 50GB, Data Storage 100GB, Rocky Linux release 8.6).
  - [ ] 3 Worker nodes.
- [ ] 2 Public IPs, and allow access to port 80 and 443.
- [ ] Domain name (pointed to one of these Public IPs):
  - fedmanager.{{ your own domain name }}
  - ds.{{ your own domain name }}
  - mdq.{{ your own domain name }}

---

## Nodes preparation

### Set up passwordless login to the Kubernetes nodes

1. Login to the Login node via SSH.
2. Generate a ssh key by using the ``ssh-keygen`` command.

   ```bash
     ssh-keygen -t ecdsa
   ```

   You don't have to set a passphrase for the private key for this purpose.
3. Copy the public key to each kubernetes node. In this tutorial we assume that a service account/user ```ifirexman``` is exist on each node.

   ```bash
     ssh-copy-id -i ~/.ssh/id_ecdsa.pub ifirexman@<kubernetes nodes ip address>
   ```

4. Try to login to each kubernetes node by using SSH. If you able to login to each node without having to key-in password, then you have successfully setup passwordless login to the kubernetes nodes.

### Set up Docker Engine

At each kubernetes nodes, you need install Docker Engine from Docker. Before you perform the steps below, you need to perform these steps as user ```root``` or as a user with ```sudo``` permission. If you choose the later one, you need to add ```sudo``` command for each command.

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
    systemctl start docker && sudo systemctl enable docker
    systemctl start containerd && sudo systemctl enable containerd
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

#### ```kubectl```

The Kubernetes command-line tool, [kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/), allows you to run commands against Kubernetes clusters. You can use ```kubectl``` to deploy applications, inspect and manage cluster resources, and view logs. For more information including a complete list of kubectl operations, see the ```kubectl``` [reference documentation](https://kubernetes.io/docs/reference/kubectl/).

To install ```kubectl``` at the login node:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin
```

#### ```kubectx``` and ```kubens```

```kubectx``` is a tool to switch between contexts (clusters) on kubectl faster while ```kubens``` is a tool to switch between Kubernetes namespaces (and configure them for kubectl) easily.

To install ```kubectx``` and ```kubens``` at the login node:

```bash
wget https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubectx_v0.9.4_linux_x86_64.tar.gz
wget https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubens_v0.9.4_linux_x86_64.tar.gz
tar zxf kubectx_v0.9.4_linux_x86_64.tar.gz
tar zxf kubens_v0.9.4_linux_x86_64.tar.gz
chmod +x kubectx
chmod +x kubens
mv kubectx /usr/local/bin/
mv kubens /usr/local/bin/
```

#### ```k9s```

K9s is a terminal based UI to interact with your Kubernetes clusters. K9s continually watches Kubernetes for changes and offers subsequent commands to interact with your observed resources.

To install ```k9``` at the login node:

```bash
wget https://github.com/derailed/k9s/releases/download/v0.26.3/k9s_Linux_x86_64.tar.gz
tar zxf k9s_Linux_x86_64.tar.gz
chmod +x k9s
mv k9s /usr/local/bin
```

#### ```rke```

Rancher Kubernetes Engine (RKE) is a CNCF-certified Kubernetes distribution that runs entirely within Docker containers. It works on bare-metal and virtualized servers. With RKE, the installation and operation of Kubernetes are both simplified and easily automated, and they are entirely independent of the operating system and platform you’re running.

To install ```rke``` at the login node:

```bash
curl -Lo rke https://github.com/rancher/rke/releases/download/v1.3.14/rke_linux-amd64
chmod +x ./rke
mv rke /usr/local/bin/
```

--- 
### Prepare Kubernetes Cluster file

To setup a kubernetes cluster by using ```rke```, first we need to create a ```cluster.yml``` file which consist of our kubernetes cluster configuration from the Login node. Below is an example of a ```cluster.yml``` file which you can use for this training.

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

## Set up Longhorn block storage
- pass.

---

## Configure load balancer (MetalLB) and Nginx Ingress
- pass.