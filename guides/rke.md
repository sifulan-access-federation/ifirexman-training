# How to set up Kubernetes Cluster

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

## Master and Worker nodes preparation

### Set up passwordless login to the Kubernetes nodes
- pass.

### Set up docker
```sh
sudo yum remove docker \
                docker-client \
                docker-client-latest \
                docker-common \
                docker-latest \
                docker-latest-logrotate \
                docker-logrotate \
                docker-engine
```

```sh
sudo yum install -y yum-utils

sudo yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
```

```sh
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

```sh
sudo systemctl start docker && sudo systemctl enable docker
sudo systemctl start containerd && sudo systemctl enable containerd
```

```sh
sudo usermod -aG docker $USER
```

### Disable swap
```sh
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
```

### Stop and disable firewall
```sh
sudo systemctl stop firewalld && sudo systemctl disable firewalld
```

### Modify bridge adapter settings
```sh
sudo modprobe br_netfilter

sudo vi /etc/sysctl.d/kubernetes.conf
## start of file
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
## end of file
```

---

## Login node preparation

### Install pre-requisites
#### `kubectl`
```sh
# add kubernetes.repo to yum repo
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# install kubectl
sudo yum install -y kubectl

# check installation
kubectl version --client
```

#### `rke`
```sh
# download rke binary
curl -Lo rke https://github.com/rancher/rke/releases/download/v1.3.13/rke_linux-amd64

# make rke executable
chmod +x ./rke

# move rke to path
sudo mv ./rke /usr/local/bin/rke

# check installation
rke --version
```

### Prepare Kubernetes Cluster file
Create a `cluster.yml` file from your Login node with this content:
```yaml
# Cluster Nodes
nodes:
  - address: {{ IP_ADDRESS }}
    user: root
    role: 
      - controlplane
      - etcd
    docker_socket: /var/run/docker.sock
  - address: {{ IP_ADDRESS }}
    user: root
    role:
      - controlplane
      - etcd
    docker_socket: /var/run/docker.sock
  - address: {{ IP_ADDRESS }}
    user: root
    role:
      - controlplane
      - etcd
    docker_socket: /var/run/docker.sock
  - address: {{ IP_ADDRESS }}
    user: root
    role:
      - worker
    docker_socket: /var/run/docker.sock
  - address: {{ IP_ADDRESS }}
    user: root
    role:
      - worker
    docker_socket: /var/run/docker.sock
  - address: {{ IP_ADDRESS }}
    user: root
    role:
      - worker
    docker_socket: /var/run/docker.sock

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
Replace all `{{ IP_ADDRESS }}` according to your Master and Worker nodes' IP address eg. `172.16.129.21`.

### Provision your cluster
Run the following command from the same directory as your `cluster.yml` file:
```sh
rke up
```

### Add cluster to your context
When the cluster has been provisioned, the following files will be generated in the root directory:
- `cluster.rkestate` - the cluster state file.
- `kube_config_cluster.yml` - the kube config file.

To add the cluster to your context, copy the kube config file
```sh
# create .kube folder in your home directory
mkdir -p ~/.kube

# copy kube config file
cp kube_config_cluster.yml ~/.kube/config
```

### Check your cluster
To ensure that your cluster of nodes is running and your host machine can connect to your cluster, run the following commands:
```sh
# get cluster information
kubectl cluster-info

# get nodes information
kubectl get nodes
```

---

## Set up Longhorn block storage
- pass.

---

## Configure load balancer (MetalLB) and Nginx Ingress
- pass.