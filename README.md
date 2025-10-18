# DIO - Trilha .NET - Nuvem com Microsoft Azure
www.dio.me

## Desafio de projeto
Para este desafio, você precisará usar seus conhecimentos adquiridos no módulo de Nuvem com Microsoft Azure, da trilha .NET da DIO.

## Contexto
Você precisa construir um sistema de RH, onde para essa versão inicial do sistema o usuário poderá cadastrar os funcionários de uma empresa. 

Essa cadastro precisa precisa ter um CRUD, ou seja, deverá permitir obter os registros, criar, salvar e deletar esses registros. A sua aplicação também precisa armazenar logs de toda e qualquer alteração que venha a ocorrer com um funcionário.

## Premissas
A sua aplicação deverá ser do tipo Web API, Azure Functions ou MVC, fique a vontade para implementar a solução que achar mais adequado.

A sua aplicação deverá ser implantada no Microsoft Azure, utilizando o App Service para a API, SQL Database para o banco relacional e Azure Table para armazenar os logs.

A sua aplicação deverá armazenar os logs de todas as alterações que venha a acontecer com o funcionário. Os logs deverão serem armazenados em uma Azure Table.

A sua classe principal, a classe Funcionario e a FuncionarioLog, deve ser a seguinte:

![Diagrama da classe Funcionario](Imagens/diagrama_classe.png)

A classe FuncionarioLog é filha da classe Funcionario, pois o log terá as mesmas informações da Funcionario.

Não se esqueça de gerar a sua migration para atualização no banco de dados.

## Métodos esperados
É esperado que você crie o seus métodos conforme a seguir:

**Swagger**

![Métodos Swagger](Imagens/swagger.png)

**Endpoints**

| Verbo  | Endpoint                | Parâmetro | Body               |
|--------|-------------------------|-----------|--------------------|
| GET    | /Funcionario/{id}       | id        | N/A                |
| PUT    | /Funcionario/{id}       | id        | Schema Funcionario |
| DELETE | /Funcionario/{id}       | id        | N/A                |
| POST   | /Funcionario            | N/A       | Schema Funcionario |

Esse é o schema (model) de Funcionario, utilizado para passar para os métodos que exigirem:

```json
{
  "nome": "Nome funcionario",
  "endereco": "Rua 1234",
  "ramal": "1234",
  "emailProfissional": "email@email.com",
  "departamento": "TI",
  "salario": 1000,
  "dataAdmissao": "2022-06-23T02:58:36.345Z"
}
```

## Ambiente
Este é um diagrama do ambiente que deverá ser montado no Microsoft Azure, utilizando o App Service para a API, SQL Database para o banco relacional e Azure Table para armazenar os logs.

![Diagrama da classe Funcionario](Imagens/diagrama_api.png)

## ✅ Implementações Realizadas

### 🔧 Funcionalidades Completadas
- ✅ **CRUD Completo de Funcionários**
  - ✅ GET `/Funcionario/{id}` - Obter funcionário por ID
  - ✅ POST `/Funcionario` - Criar novo funcionário
  - ✅ PUT `/Funcionario/{id}` - Atualizar funcionário existente
  - ✅ DELETE `/Funcionario/{id}` - Remover funcionário

- ✅ **Sistema de Logs**
  - ✅ Logs automáticos para todas as operações (CREATE, UPDATE, DELETE)
  - ✅ Armazenamento no Azure Table Storage
  - ✅ Modelo `FuncionarioLog` herdando de `Funcionario`

- ✅ **Banco de Dados**
  - ✅ Entity Framework Core configurado
  - ✅ SQLite para desenvolvimento local
  - ✅ SQL Server para produção no Azure
  - ✅ Migrações criadas e aplicadas

- ✅ **Documentação da API**
  - ✅ Swagger UI configurado e funcional
  - ✅ Documentação XML nas ações do controller
  - ✅ Respostas HTTP apropriadas

### 🛠️ Tecnologias Utilizadas
- **Framework**: .NET 9.0
- **ORM**: Entity Framework Core
- **Banco Local**: SQLite
- **Banco Produção**: SQL Server
- **Storage**: Azure Table Storage
- **Documentação**: Swagger/OpenAPI
- **Cloud**: Microsoft Azure

### 🏃‍♂️ Como Executar Localmente

1. **Pré-requisitos**
   ```bash
   # .NET 9.0 SDK instalado
   # Git instalado
   ```

2. **Clone e Execute**
   ```bash
   git clone <repositorio>
   cd trilha-net-azure-desafio
   dotnet restore
   dotnet ef database update
   dotnet run
   ```

3. **Acesse a API**
   - API: `https://localhost:7090`
   - Swagger: `https://localhost:7090/swagger`

### 📝 Testando a API

Use o arquivo `funcionario-exemplo.json` para testar os endpoints:

```json
{
  "nome": "João Silva",
  "endereco": "Rua das Flores, 123 - São Paulo, SP",
  "ramal": "1234",
  "emailProfissional": "joao.silva@empresa.com",
  "departamento": "TI",
  "salario": 5000.00,
  "dataAdmissao": "2023-01-15T08:00:00.000Z"
}
```

### 🚀 Deploy no Azure

Para fazer o deploy no Microsoft Azure, consulte os arquivos:
- 📖 **[DEPLOY_AZURE.md](DEPLOY_AZURE.md)** - Instruções detalhadas
- 🔧 **[deploy-azure.ps1](deploy-azure.ps1)** - Script automatizado

#### Deploy Rápido
```powershell
./deploy-azure.ps1 -SqlAdminPassword "MinhaSenh@123!"
```

### 📊 Estrutura do Projeto

```
├── Controllers/
│   └── FuncionarioController.cs    # Endpoints da API
├── Models/
│   ├── Funcionario.cs              # Modelo principal
│   ├── FuncionarioLog.cs           # Modelo para logs
│   └── TipoAcao.cs                 # Enum para tipos de ação
├── Context/
│   └── RHContext.cs                # Contexto do Entity Framework
├── Migrations/                     # Migrações do banco
├── appsettings.json               # Configurações de produção
├── appsettings.Development.json   # Configurações de desenvolvimento
└── Program.cs                     # Configuração da aplicação
```

### 🔍 Funcionalidades Implementadas

#### 1. Controller Completo
- Validações de entrada
- Tratamento de erros
- Retornos HTTP apropriados
- Documentação XML

#### 2. Sistema de Logs
- Log automático para todas as operações
- Armazenamento no Azure Table Storage
- Serialização JSON dos dados

#### 3. Configurações Flexíveis
- SQLite para desenvolvimento
- SQL Server para produção
- Connection strings configuráveis

### 🎯 Próximos Passos

Para continuar melhorando o projeto:

1. **Autenticação e Autorização**
   ```csharp
   // Implementar JWT ou Azure AD
   ```

2. **Validações Avançadas**
   ```csharp
   // Data Annotations ou FluentValidation
   ```

3. **Paginação e Filtros**
   ```csharp
   // GET /Funcionario?page=1&size=10&departamento=TI
   ```

4. **Testes Unitários**
   ```csharp
   // xUnit + Moq
   ```

### 📞 Suporte

Para dúvidas ou problemas:
- 📧 Consulte a documentação do [.NET](https://docs.microsoft.com/dotnet/)
- 🌐 Visite o [Portal do Azure](https://portal.azure.com)
- 🎓 Acesse a [DIO](https://dio.me)

---

✨ **Projeto desenvolvido com sucesso!** ✨

Todos os TODOs foram implementados e a aplicação está pronta para uso em desenvolvimento e produção no Microsoft Azure.