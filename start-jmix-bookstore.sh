#!/bin/bash

mkdir -p "$HOME/.ssh"
SSH_PATH="$HOME/.ssh/ipris_task"
ssh-keygen -t rsa -f $SSH_PATH -N ""
SSH_KEY=$(cat "$SSH_PATH.pub")

NETWORK_NAME='task3'
SUBNET_NAME='sub3'

yc vpc network create --name $NETWORK_NAME
yc vpc subnet create --name $SUBNET_NAME --network-name $NETWORK_NAME --range '192.168.0.0/24' --zone 'ru-central1-b'

VM_USERNAME='ipiris'
VM_NAME='task3_vm'
CONFIG_FILE='metadata.yaml'

cat <<EOF > "$CONFIG_FILE"
#cloud-config
users:
- name: $VM_USERNAME
  sudo: 'ALL=(ALL) NOPASSWD:ALL'
  shell: /bin/bash
  ssh_authorized_keys:
  - $SSH_KEY
EOF

yc compute instance create \
  --name $VM_NAME \
  --zone ru-central1-b \
  --platform standard-v3 \
  --cores 2 \
  --memory 4GB \
  --network-interface subnet-name=$SUBNET_NAME,nat-ip-version=ipv4 \
  --create-boot-disk size=20,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-24-04-lts \
  --metadata-from-file user-data=$CONFIG_FILE'

IP_ADDRESS=$(yc compute instance get $VM_NAME | grep -A 2 'one_to_one_nat' | grep 'address' | tr -d ' ' | cut -d':' -f2)

ssh -T -o StrictHostKeyChecking=no -i $SSH_PATH $VM_USERNAME@$IP_ADDRESS << 'EOF'
sudo apt-get update
sudo apt-get install -y docker.io
sudo docker rud -d --name task3-app -p 8080:8080 jmix/jmix-bookstore
EOF

echo "ssh connection: ssh -i $SSH_PATH $VM_USERNAME@$IP_ADDRESS"
echo "Web App: http://$IP_ADDRESS"
