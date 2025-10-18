# Script de Deploy para Azure
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName = "rg-funcionarios-app",
    
    [Parameter(Mandatory=$true)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$true)]
    [string]$SqlServerName = "sql-funcionarios-server",
    
    [Parameter(Mandatory=$true)]
    [string]$SqlAdminUser = "adminuser",
    
    [Parameter(Mandatory=$true)]
    [string]$SqlAdminPassword,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName = "stfuncionariosapp",
    
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName = "app-funcionarios-rh"
)

Write-Host "🚀 Iniciando deploy no Azure..." -ForegroundColor Green

# 1. Criar Grupo de Recursos
Write-Host "📦 Criando grupo de recursos..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location

# 2. Criar SQL Server e Database
Write-Host "🗄️ Criando SQL Server..." -ForegroundColor Yellow
az sql server create `
  --name $SqlServerName `
  --resource-group $ResourceGroupName `
  --location $Location `
  --admin-user $SqlAdminUser `
  --admin-password $SqlAdminPassword

Write-Host "📊 Criando SQL Database..." -ForegroundColor Yellow
az sql db create `
  --resource-group $ResourceGroupName `
  --server $SqlServerName `
  --name "FuncionariosDB" `
  --service-objective "Basic"

# 3. Criar Storage Account
Write-Host "💾 Criando Storage Account..." -ForegroundColor Yellow
az storage account create `
  --name $StorageAccountName `
  --resource-group $ResourceGroupName `
  --location $Location `
  --sku "Standard_LRS"

# 4. Criar App Service Plan e Web App
Write-Host "🌐 Criando App Service..." -ForegroundColor Yellow
az appservice plan create `
  --name "plan-funcionarios-app" `
  --resource-group $ResourceGroupName `
  --sku "B1" `
  --is-linux

az webapp create `
  --resource-group $ResourceGroupName `
  --plan "plan-funcionarios-app" `
  --name $AppServiceName `
  --runtime "DOTNETCORE:9.0"

# 5. Obter Connection Strings
Write-Host "🔗 Obtendo connection strings..." -ForegroundColor Yellow
$sqlConnectionString = az sql db show-connection-string `
  --client "ado.net" `
  --server $SqlServerName `
  --name "FuncionariosDB" | ConvertFrom-Json

$storageConnectionString = az storage account show-connection-string `
  --name $StorageAccountName `
  --resource-group $ResourceGroupName `
  --query "connectionString" `
  --output tsv

# Substituir placeholders na connection string do SQL
$sqlConnectionString = $sqlConnectionString.Replace("<username>", $SqlAdminUser)
$sqlConnectionString = $sqlConnectionString.Replace("<password>", $SqlAdminPassword)

# 6. Configurar Connection Strings no App Service
Write-Host "⚙️ Configurando variáveis de ambiente..." -ForegroundColor Yellow
az webapp config connection-string set `
  --resource-group $ResourceGroupName `
  --name $AppServiceName `
  --settings "ConexaoPadrao=$sqlConnectionString" `
  --connection-string-type "SQLAzure"

az webapp config appsettings set `
  --resource-group $ResourceGroupName `
  --name $AppServiceName `
  --settings `
    "ConnectionStrings:SAConnectionString=$storageConnectionString" `
    "ConnectionStrings:AzureTableName=FuncionarioLog"

# 7. Publicar aplicação
Write-Host "📦 Publicando aplicação..." -ForegroundColor Yellow
dotnet publish --configuration Release --output "./publish"

# Criar arquivo zip
if (Test-Path "./app.zip") {
    Remove-Item "./app.zip"
}
Compress-Archive -Path "./publish/*" -DestinationPath "./app.zip"

# 8. Deploy no Azure
Write-Host "🚀 Fazendo deploy..." -ForegroundColor Yellow
az webapp deployment source config-zip `
  --resource-group $ResourceGroupName `
  --name $AppServiceName `
  --src "./app.zip"

# 9. Configurar firewall do SQL Server para permitir Azure Services
Write-Host "🔒 Configurando firewall..." -ForegroundColor Yellow
az sql server firewall-rule create `
  --resource-group $ResourceGroupName `
  --server $SqlServerName `
  --name "AllowAllAzureServices" `
  --start-ip-address "0.0.0.0" `
  --end-ip-address "0.0.0.0"

Write-Host "✅ Deploy concluído com sucesso!" -ForegroundColor Green
Write-Host "🌐 URL da aplicação: https://$AppServiceName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "📖 Swagger: https://$AppServiceName.azurewebsites.net/swagger" -ForegroundColor Cyan

# Limpar arquivos temporários
Remove-Item "./publish" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "./app.zip" -ErrorAction SilentlyContinue

Write-Host "🗄️ Para executar as migrações no banco de produção, execute:" -ForegroundColor Magenta
Write-Host "dotnet ef database update --connection '$sqlConnectionString'" -ForegroundColor White
