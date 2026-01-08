// Mandatory params
param dnsPrefix string = resourceGroup().name
param clusterName string = 'devsecops-aks'
param akvName string = 'akv-${uniqueString(resourceGroup().id)}'

// Optional params
param location string = resourceGroup().location
param agentCount int = 3
param agentVMSize string = 'Standard_DS2_v2'

// ACR
resource acr 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
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

// AKS
resource aks 'Microsoft.ContainerService/managedClusters@2025-04-01' = {
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
      workloadIdentity: {
        enabled: true
      }
    }
  }
}

// Key Vault
resource akv 'Microsoft.KeyVault/vaults@2025-05-01' = {
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

// Output
output controlPlaneFQDN string = aks.properties.fqdn
