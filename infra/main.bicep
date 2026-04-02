targetScope = 'resourceGroup'

@description('リソースのデプロイ先リージョン')
param location string = 'swedencentral'

@description('AI Services アカウント名（グローバルで一意）')
param accountName string

@description('Foundry プロジェクト名')
param projectName string = 'foundry-agent-eval'

@description('デプロイするモデル名（例: gpt-5.4, gpt-4.1, gpt-4o）')
param modelName string = 'gpt-5.4'

@description('モデルデプロイメント名（.env の MODEL_DEPLOYMENT_NAME に対応）')
param modelDeploymentName string = modelName

@description('モデルの SKU 名')
param modelSkuName string = 'GlobalStandard'

@description('モデルの TPM キャパシティ（千トークン/分）')
param modelCapacity int = 10

var commonTags = {
  SecurityControl: 'Ignore'
  CostControl: 'Ignore'
}

// AI Services アカウント（Foundry のホスト）
resource aiServices 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: accountName
  location: location
  kind: 'AIServices'
  sku: { name: 'S0' }
  tags: commonTags
  properties: {
    customSubDomainName: accountName
    publicNetworkAccess: 'Enabled'
    allowProjectManagement: true
  }
}

// Foundry プロジェクト
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  parent: aiServices
  name: projectName
  location: location
  tags: commonTags
  properties: {
    displayName: projectName
  }
}

// モデルデプロイメント
resource modelDeploy 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: aiServices
  name: modelDeploymentName
  sku: {
    name: modelSkuName
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
    }
  }
}

@description('.env の PROJECT_ENDPOINT に設定する値')
output projectEndpoint string = 'https://${accountName}.services.ai.azure.com/api/projects/${projectName}'

@description('モデルデプロイメント名')
output modelDeployment string = modelDeploy.name
