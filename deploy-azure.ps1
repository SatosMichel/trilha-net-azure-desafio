# Script de Deploy para Azure (Versao Final com Nomes Unicos)
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName = "rg-funcionarios-app",
    [Parameter(Mandatory=$true)]
    [string]$Location = "Brazil South",
    [Parameter(Mandatory=$true)]
    [string]$SqlServerName = "sql-funcionarios-server-$(Get-Random -Minimum 1000 -Maximum 9999)",
    [Parameter(Mandatory=$true)]
    [string]$SqlAdminUser = "adminuser",
    [Parameter(Mandatory=$true)]
    [string]$SqlAdminPassword,
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName = "stfuncionariosapp$(Get-Random -Minimum 1000 -Maximum 9999)",
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName = "app-funcionarios-rh-$(Get-Random -Minimum 1000 -Maximum 9999)"
)

Write-Host "Iniciando deploy no Azure..." -ForegroundColor Green

# 1. Criar Grupo de Recursos
Write-Host "Criando grupo de recursos..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location

# 2. Criar SQL Server e Database
Write-Host "Criando SQL Server..." -ForegroundColor Yellow
az sql server create `
  --name $SqlServerName `
  --resource-group $ResourceGroupName `
  --location $Location `
  --admin-user $SqlAdminUser `
  --admin-password $SqlAdminPassword

Write-Host "Criando SQL Database..." -ForegroundColor Yellow
az sql db create `
  --resource-group $ResourceGroupName `
  --server $SqlServerName `
  --name "FuncionariosDB" `
  --service-objective "Basic"

# 3. Criar Storage Account
Write-Host "Criando Storage Account..." -ForegroundColor Yellow
az storage account create `
  --name $StorageAccountName `
  --resource-group $ResourceGroupName `
  --location $Location `
  --sku "Standard_LRS"

# 4. Criar App Service Plan e Web App
Write-Host "Criando App Service..." -ForegroundColor Yellow
az appservice plan create `
  --name "plan-funcionarios-app" `
  --resource-group $ResourceGroupName `
  --sku "F1" `
  --is-linux

az webapp create `
  --resource-group $ResourceGroupName `
  --plan "plan-funcionarios-app" `
  --name $AppServiceName `
  --runtime "DOTNETCORE:8.0"

# 5. Obter Connection Strings
Write-Host "Obtendo connection strings..." -ForegroundColor Yellow
$sqlConnectionString = az sql db show-connection-string `
  --client "ado.net" `
  --server $SqlServerName `
  --name "FuncionariosDB" `
  --output tsv

$storageConnectionString = az storage account show-connection-string `
  --name $StorageAccountName `
  --resource-group $ResourceGroupName `
  --query "connectionString" `
  --output tsv

$sqlConnectionString = $sqlConnectionString.Replace("<username>", $SqlAdminUser)
$sqlConnectionString = $sqlConnectionString.Replace("<password>", $SqlAdminPassword)

# 6. Configurar Connection Strings no App Service
Write-Host "Configurando variaveis de ambiente..." -ForegroundColor Yellow
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

# 7. Publicar aplicacao
Write-Host "Publicando aplicacao..." -ForegroundColor Yellow
dotnet publish --configuration Release --output "./publish"

# Criar arquivo zip
if (Test-Path "./app.zip") {
    Remove-Item "./app.zip"
}
Compress-Archive -Path "./publish/*" -DestinationPath "./app.zip"

# 8. Deploy no Azure
Write-Host "Fazendo deploy..." -ForegroundColor Yellow
az webapp deployment source config-zip `
  --resource-group $ResourceGroupName `
  --name $AppServiceName `
  --src "./app.zip"

# 9. Configurar firewall do SQL Server
Write-Host "Configurando firewall..." -ForegroundColor Yellow
az sql server firewall-rule create `
  --resource-group $ResourceGroupName `
  --server $SqlServerName `
  --name "AllowAllAzureServices" `
  --start-ip-address "0.0.0.0" `
  --end-ip-address "0.0.0.0"

Write-Host "Deploy concluido com sucesso!" -ForegroundColor Green
Write-Host "URL da aplicacao: https://$AppServiceName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "Swagger: https://$AppServiceName.azurewebsites.net/swagger" -ForegroundColor Cyan

# Limpar arquivos temporarios
Remove-Item "./publish" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "./app.zip" -ErrorAction SilentlyContinue

# Comando de migracao
$MigrationCommand = "dotnet ef database update --connection `"$sqlConnectionString`""
Write-Host "Para executar as migracoes no banco de producao, copie e execute o comando abaixo:" -ForegroundColor Magenta
Write-Host $MigrationCommand -ForegroundColor White

