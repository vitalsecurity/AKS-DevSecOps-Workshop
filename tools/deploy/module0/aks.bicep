// -----------------------------
// Mandatory parameters
// -----------------------------

@description('The unique DNS prefix for your cluster, such as myakscluster. This cannot be updated once the Managed Cluster has been created.')
param dnsPrefix string = resourceGroup().name

@description('The unique name for the AKS cluster, such as myAKSCluster.')
param clusterName string = 'devsecops-aks'

@description('The unique name for the Azure Key Vault.')
param akvName string = 'akv-${uniqueString(resourceGroup().id)}'

// -----------------------------
// Optional parameters
// -----------------------------

@description('The region to deploy the cluster. By default this will use the same region as the resource group.')
param location string = resourceGroup().location

@minValue(1)
@maxValue(50)
@description('Number of agents (VMs) to host docker containers.')
param agentCount int = 3

@description('VM size for the agent nodes.')
param agentVMSize string = 'Standard_DS2_v2'

// -----------------------------
// Azure Container Registry
// -----------------------------

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'acr${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    adminUserEnabled: true
  }
}

// -----------------------------
// AKS Cluster
// -----------------------------

resource aks 'Microsoft.ContainerService/managedClusters@2023-09-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
      }
    ]
    aadProfile: {
      managed: true
      enableAzureRBAC: true
    }
  }
}

// -----------------------------
// Azure Key Vault
// -----------------------------

resource akv 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: akvName
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: aks.identity.principalId
        permissions: {
          keys: [
            'get'
          ]
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

// -----------------------------
// Outputs
// -----------------------------

output controlPlaneFQDN string = aks.properties.fqdn
