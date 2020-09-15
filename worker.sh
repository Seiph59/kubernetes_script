#!/bin/bash

#Tested on Ubuntu 18.04.5
version=1.18.1 # Kubernetes Version

#### Ask the user admin ####
while :
do
  clear
  echo " ##########################################################################"
  echo " ##########################################################################"
  echo "          WELCOME TO WORKER-NODE SCRIPT FOR UBUNTU 18.04.5"
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
