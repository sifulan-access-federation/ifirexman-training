# Provision Kubernetes Cluster with RKE

## Resources
[Setting up Rancher on Your Local Machine with an RKE Provisioned Cluster](https://community.suse.com/posts/setting-up-rancher-on-your-local-machine-with-an-rke-provisioned-cluster)

## Pre-flight checklist
- [ ] 4 VMs (CPU Cores 4, RAM 8GB, Storage 25GB, Rocky Linux release 8.6).
- [ ] 3 VMs (CPU Cores >=8, RAM >=16GB, OS Storage 50GB, Data Storage 100GB, Rocky Linux release 8.6).
- [ ] 2 Public IPs, and allow access to port 80 and 443.
- [ ] Domain name (pointed to one of these Public IPs):
  - fedmanager.{{ your own domain name }}
  - ds.{{ your own domain name }}
  - mdq.{{ your own domain name }}
- [ ] Disable swap on each worker nodes.
- [ ] Modify network bridge settings.

## Walkthrough

### Prepare your RKE config
Create a `cluster.yml` file with this content:
```yaml
# Cluster Nodes
nodes:
  - address: 172.16.129.21
    user: root
    role: 
      - controlplane
      - etcd
      - worker
    docker_socket: /var/run/docker.sock
  - address: 172.16.129.22
    user: root
    role:
      - controlplane
      - etcd
      - worker
    docker_socket: /var/run/docker.sock
  - address: 172.16.129.23
    user: root
    role:
      - controlplane
      - etcd
      - worker
    docker_socket: /var/run/docker.sock

# Name of the K8s Cluster
cluster_name: rancher-cluster

services:
  kube-api:
    # IP range for any services created on Kubernetes
    # This must match the service_cluster_ip_range in kube-controller
    service_cluster_ip_range: 172.16.0.0/16
    # Expose a different port range for NodePort services
    service_node_port_range: 30000-32767    
    pod_security_policy: false

  kube-controller:
    # CIDR pool used to assign IP addresses to pods in the cluster
    cluster_cidr: 172.15.0.0/16
    # IP range for any services created on Kubernetes
    # This must match the service_cluster_ip_range in kube-api
    service_cluster_ip_range: 172.16.0.0/16
  
  kubelet:
    # Base domain for the cluster
    cluster_domain: cluster.local
    # IP address for the DNS service endpoint
    cluster_dns_server: 172.16.0.10
    # Fail if swap is on
    fail_swap_on: false

network:
  plugin: calico

# Specify DNS provider (coredns or kube-dns)
dns:
  provider: coredns

# Kubernetes Authorization mode
# Enable RBAC
authorization:
  mode: rbac

# Specify monitoring provider (metrics-server)
monitoring:
  provider: metrics-server
```
Replace the IP addresses and IP range used in the above `cluster.yml` according to your node configurations.

### Provision your cluster
Run the following command on your host machine from the same directory as your `cluster.yml` file:
```sh
rke up
```

### Add cluster to your context
When the cluster has been provisioned, the following files will be generated in the root directory:
- `cluster.rkestate` - the cluster state file
- `kube_config_cluster.yml` - the kube config file

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