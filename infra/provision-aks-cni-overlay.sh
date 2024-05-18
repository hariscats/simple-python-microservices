#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 <your_email@example.com>"
  exit 1
}

# Check if email is provided as an argument
if [ -z "$1" ]; then
  usage
fi

# Variables
EMAIL=$1
RESOURCE_GROUP="myAksDemoRg"
LOCATION="eastus"
AKS_CLUSTER_NAME="myDemoAKSCluster"
ACR_BASE_NAME="myacr"
AKS_NODE_COUNT=3
AKS_NODE_VM_SIZE="Standard_DS2_v2"
K8S_VERSION="1.28.5"
VNET_NAME="myVNet"
SUBNET_NAME="mySubnet"
VNET_CIDR="10.10.0.0/16"
SUBNET_CIDR="10.10.1.0/24"
SSH_KEY_NAME="my_ssh_key"
SSH_KEY_PATH="$HOME/.ssh/${SSH_KEY_NAME}"

# Generate a unique name for the ACR
ACR_NAME="${ACR_BASE_NAME}$(openssl rand -hex 3)"

# Create SSH key pair if it doesn't exist
if [ ! -f "${SSH_KEY_PATH}" ]; then
  echo "Creating SSH key pair..."
  ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "${SSH_KEY_PATH}" -N ""
  if [ $? -ne 0 ]; then
    echo "Failed to create SSH key pair."
    exit 1
  fi
fi

SSH_PUBLIC_KEY=$(cat "${SSH_KEY_PATH}.pub")

# Create Resource Group
echo "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION
if [ $? -ne 0 ]; then
  echo "Failed to create resource group."
  exit 1
fi

# Create Virtual Network
echo "Creating virtual network..."
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefix $VNET_CIDR \
  --subnet-name $SUBNET_NAME \
  --subnet-prefix $SUBNET_CIDR
if [ $? -ne 0 ]; then
  echo "Failed to create virtual network."
  exit 1
fi

# Get the subnet ID
SUBNET_ID=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $SUBNET_NAME --query id --output tsv)
if [ -z "$SUBNET_ID" ]; then
  echo "Failed to get subnet ID."
  exit 1
fi

# Create Azure Container Registry
echo "Creating Azure Container Registry with name $ACR_NAME..."
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic
if [ $? -ne 0 ]; then
  echo "Failed to create Azure Container Registry."
  exit 1
fi

# Create AKS cluster with Azure CNI Overlay and SSH key
echo "Creating AKS cluster with Azure CNI Overlay..."
az aks create \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_NODE_COUNT \
  --node-vm-size $AKS_NODE_VM_SIZE \
  --kubernetes-version $K8S_VERSION \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --vnet-subnet-id $SUBNET_ID \
  --ssh-key-value "$SSH_PUBLIC_KEY" 
if [ $? -ne 0 ]; then
  echo "Failed to create AKS cluster."
  exit 1
fi

# Attach ACR to AKS
echo "Attaching ACR to AKS..."
az aks update -n $AKS_CLUSTER_NAME -g $RESOURCE_GROUP --attach-acr $ACR_NAME
if [ $? -ne 0 ]; then
  echo "Failed to attach ACR to AKS."
  exit 1
fi

# Get AKS credentials
echo "Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME
if [ $? -ne 0 ]; then
  echo "Failed to get AKS credentials."
  exit 1
fi

# Get the node resource group
NODE_RESOURCE_GROUP=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query nodeResourceGroup --output tsv)
if [ -z "$NODE_RESOURCE_GROUP" ]; then
  echo "Failed to get node resource group."
  exit 1
fi

# Create NSG rule to allow SSH access to the nodes
echo "Creating NSG rule to allow SSH access to the nodes..."
NSG_NAME=$(az network nsg list --resource-group $NODE_RESOURCE_GROUP --query '[0].name' --output tsv)
if [ -z "$NSG_NAME" ]; then
  echo "Failed to get NSG name."
  exit 1
fi

az network nsg rule create --resource-group $NODE_RESOURCE_GROUP --nsg-name $NSG_NAME --name AllowSSH --protocol Tcp --direction Inbound --priority 1000 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --access Allow
if [ $? -ne 0 ]; then
  echo "Failed to create NSG rule."
  exit 1
fi

echo "Provisioning complete. Your AKS cluster with Azure CNI Overlay, ACR ($ACR_NAME), and SSH access is ready."
