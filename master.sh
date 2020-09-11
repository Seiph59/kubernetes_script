#!/bin/bash

#Tested on Ubuntu 18.04.5
version=1.18.1

#### Ask the user admin ####
while :
do
  clear
  echo " ##########################################################################"
  echo " ##########################################################################"
  echo "          WELCOME TO MASTER-NODE SCRIPT FOR UBUNTU 18.04.5"
  echo "            THE SCRIPT WILL INSTALL KUBERNETES 1.18.1 "
  echo " ##########################################################################"
  echo " PLEASE ENTER THE USERNAME THAT WILL ADMINISTER THE CLUSTER (ROOT EXCLUDED)"
  echo " ##########################################################################"
  read user 

  # Check if the user exists
  count=$(grep -wc $user /etc/passwd)
  if [ $count -gt 0 ]; then 
    break
  else
    echo "The Username does not exist, please try again !"
    sleep 2s
  fi
done

# Set new environment
echo "$user ALL=(ALL) ALL" > /etc/sudoers.d/$user
chmod 440 /etc/sudoers.d/$user
PATH=$PATH:/usr/sbin:/sbin

# Update the system
apt-get update && apt-get upgrade -y

# Install vim and Docker
apt-get install -y vim docker.io

# Add new repo for Kubernetes
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

# Add the GPG key for the packages
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# Update the system
apt-get update

# Install kubeadm/kubectl/kubelet
apt-get install -y kubeadm=$version-00 kubelet=$version-00 kubectl=$version-00

# Mark these 3 new packages
apt-mark hold kubelet kubeadm kubectl

# Get Calico.yaml for CNI
if [ ! -f "calico.yaml" ]; then
  wget https://docs.projectcalico.org/manifests/calico.yaml ;
else
  echo "File 'calico.yaml' already exists."
fi

# Uncomment 2 lines in calico.yaml file
sed -i -e '/CALICO_IPV4POOL_CIDR/ s/# //' calico.yaml
sed -i -e '/192.168.0.0/ s/# //' calico.yaml

# Edit local DNS for master
ip=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
host=$(hostname)
echo -e "$ip k8smaster \n127.0.0.1 localhost \n127.0.1.1 $host"  > /etc/hosts

# Get Ip Range from calico.yaml
ipCalico=$(grep CALICO_IPV4POOL_CIDR -A1 calico.yaml | tail -n1 | cut -f2 -d":" | tr -d '"')

# Create kubeadm-config.yaml file
cat > kubeadm-config.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: $version
controlPlaneEndpoint: "k8smaster:6443"
networking:
  podSubnet: $ipCalico
EOF

# Launch and set autostart to Docker
systemctl start docker.service
systemctl enable docker.service

# Turn off the swap
swapoff -a
sed -i 's/^\/swap*/\#\/swap/' /etc/fstab 

# Initialize the master
if [ -f "kubeadm-init.out" ]; then
  echo "kubeadm init already launched"
else
  kubeadm init --config=kubeadm-config.yaml --upload-certs | tee kubeadm-init.out
fi

# Add config on user home
FOLDER=/home/$user/.kube
if [ -f "$FOLDER" ]; then
  echo "$FOLDER already exists"
else
  mkdir -p $FOLDER
  chown -R $user:$user $FOLDER
  if [ -f "$FOLDER/config" ]; then
    echo "$FOLDER/config file already exists"
  else
    cp -i /etc/kubernetes/admin.conf $FOLDER/config
    chown -R $user:$user $FOLDER/config
  fi
fi

# Apply Yaml file
chown $user:$user calico.yaml
sudo --user=$user kubectl apply -f calico.yaml

# Settings bash completion for kubectl
apt-get install bash-completion -y
sudo --user=$user source <(kubectl completion bash)
sudo --user=$user echo "source <(kubectl completion bash)" >> $HOME/.bashrc

# Bash completion Activation
echo " #########################################################"
echo "TO ACTIVATE THE BASH COMPLETION FOR KUBECTL PLEASE LOG OUT"
echo " #########################################################"
