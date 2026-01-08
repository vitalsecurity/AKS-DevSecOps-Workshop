// Mandatory Parameters
param dnsPrefix string = resourceGroup().name
param clusterName string = 'devsecops-aks'
param akvName string = 'akv-${uniqueString(resourceGroup().id)}'

// Optional Parameters
param location string = resourceGroup().location
@minValue(1)
@maxValue(50)
param agentCount int = 3
param agentVMSize string = 'Standard_DS2_v2'

// Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2025-06-01' = {
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

// AKS Cluster
resource aks 'Microsoft.ContainerService/managedClusters@2025-10-02-preview' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  enableWorkloadIdentity: true
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

// Key Vault
resource akv 'Microsoft.KeyVault/vaults@2025-06-01' = {
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
          keys: ['get']
          secrets: ['get']
        }
      }
    ]
  }
}

// Outputs
output controlPlaneFQDN string = aks.properties.fqdn
