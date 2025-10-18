# Guia de Deploy no Microsoft Azure

Este documento contém as instruções para fazer o deploy da aplicação no Microsoft Azure.

## Pré-requisitos

1. **Azure CLI** instalado
2. **Conta Azure** ativa
3. **Azure Storage Account** para o Azure Table Storage
4. **SQL Database** no Azure (para produção)

## Passos para Deploy

### 1. Criar Grupo de Recursos

```bash
az group create --name rg-funcionarios-app --location "East US"
```

### 2. Criar SQL Database

```bash
# Criar SQL Server
az sql server create \
  --name sql-funcionarios-server \
  --resource-group rg-funcionarios-app \
  --location "East US" \
  --admin-user adminuser \
  --admin-password "MinhaSenh@123!"

# Criar Database
az sql db create \
  --resource-group rg-funcionarios-app \
  --server sql-funcionarios-server \
  --name FuncionariosDB \
  --service-objective Basic
```

### 3. Criar Storage Account para Azure Tables

```bash
az storage account create \
  --name stfuncionariosapp \
  --resource-group rg-funcionarios-app \
  --location "East US" \
  --sku Standard_LRS
```

### 4. Obter Connection Strings

```bash
# SQL Database Connection String
az sql db show-connection-string \
  --client ado.net \
  --server sql-funcionarios-server \
  --name FuncionariosDB

# Storage Account Connection String
az storage account show-connection-string \
  --name stfuncionariosapp \
  --resource-group rg-funcionarios-app
```

### 5. Criar App Service

```bash
# Criar App Service Plan
az appservice plan create \
  --name plan-funcionarios-app \
  --resource-group rg-funcionarios-app \
  --sku B1 \
  --is-linux

# Criar Web App
az webapp create \
  --resource-group rg-funcionarios-app \
  --plan plan-funcionarios-app \
  --name app-funcionarios-rh \
  --runtime "DOTNETCORE:9.0"
```

### 6. Configurar Variables de Ambiente

```bash
# Configurar Connection Strings
az webapp config connection-string set \
  --resource-group rg-funcionarios-app \
  --name app-funcionarios-rh \
  --settings ConexaoPadrao="[SUA_CONNECTION_STRING_SQL]" \
  --connection-string-type SQLAzure

az webapp config appsettings set \
  --resource-group rg-funcionarios-app \
  --name app-funcionarios-rh \
  --settings \
    "ConnectionStrings:SAConnectionString=[SUA_CONNECTION_STRING_STORAGE]" \
    "ConnectionStrings:AzureTableName=FuncionarioLog"
```

### 7. Deploy da Aplicação

```bash
# Publicar aplicação
dotnet publish --configuration Release --output ./publish

# Fazer zip do conteúdo
Compress-Archive -Path "./publish/*" -DestinationPath "./app.zip"

# Deploy via Azure CLI
az webapp deployment source config-zip \
  --resource-group rg-funcionarios-app \
  --name app-funcionarios-rh \
  --src ./app.zip
```

### 8. Executar Migrações no Azure

Após o deploy, execute as migrações no banco de produção:

```bash
# Configurar connection string temporariamente
$env:ConnectionStrings__ConexaoPadrao="[SUA_CONNECTION_STRING_SQL]"

# Executar migrações
dotnet ef database update --configuration Release
```

## Configurações Importantes

### appsettings.json (Produção)

```json
{
  "ConnectionStrings": {
    "ConexaoPadrao": "Server=tcp:sql-funcionarios-server.database.windows.net,1433;Initial Catalog=FuncionariosDB;Persist Security Info=False;User ID=adminuser;Password=MinhaSenh@123!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;",
    "SAConnectionString": "DefaultEndpointsProtocol=https;AccountName=stfuncionariosapp;AccountKey=[SUA_ACCOUNT_KEY];EndpointSuffix=core.windows.net",
    "AzureTableName": "FuncionarioLog"
  }
}
```

## URLs Importantes

- **API**: https://app-funcionarios-rh.azurewebsites.net
- **Swagger**: https://app-funcionarios-rh.azurewebsites.net/swagger
- **Portal Azure**: https://portal.azure.com

## Monitoramento

Use o Application Insights para monitorar a aplicação:

```bash
az monitor app-insights component create \
  --app app-funcionarios-insights \
  --location "East US" \
  --resource-group rg-funcionarios-app
```

## Troubleshooting

1. **Erro de Connection String**: Verifique se as connection strings estão configuradas corretamente
2. **Erro de CORS**: Configure CORS se necessário para acesso via frontend
3. **Erro de SSL**: Verifique certificados SSL no Azure
