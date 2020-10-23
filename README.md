# kubernetes script

Script to automate kubernetes cluster installation on Ubuntu 18.04.5-server

## Instructions
* Copy the script(s) on the machine 
* Check if you have execution rights
* launch with **sudo ./master.sh**

## Once launched
* Enter your username

## Once the script is over
* Do not forget to log out for kubectl completion

## Worker Node
* Launch **sudo ./worker.sh** on the future worker-node

## For HA solution with multiple masters
* here is the script to install alternatives masters
* launch **sudo ./alt-master.sh** on the others master nodes
