using Azure.Data.Tables;
using Microsoft.AspNetCore.Mvc;
using TrilhaNetAzureDesafio.Context;
using TrilhaNetAzureDesafio.Models;

namespace TrilhaNetAzureDesafio.Controllers;

[ApiController]
[Route("[controller]")]
public class FuncionarioController : ControllerBase
{
    private readonly RHContext _context;
    private readonly string _connectionString;
    private readonly string _tableName;

    public FuncionarioController(RHContext context, IConfiguration configuration)
    {
        _context = context;
        _connectionString = configuration.GetValue<string>("ConnectionStrings:SAConnectionString");
        _tableName = configuration.GetValue<string>("ConnectionStrings:AzureTableName");
    }

    private TableClient GetTableClient()
    {
        if (string.IsNullOrWhiteSpace(_connectionString) || string.IsNullOrWhiteSpace(_tableName))
            return null; // retornará null se não configurado

        try
        {
            var serviceClient = new TableServiceClient(_connectionString);
            var tableClient = serviceClient.GetTableClient(_tableName);

            tableClient.CreateIfNotExists();
            return tableClient;
        }
        catch
        {
            // Se houver qualquer problema com a conexão ao Table Storage, não impede a API
            return null;
        }
    }

    /// <summary>
    /// Obtém um funcionário específico por ID
    /// </summary>
    /// <param name="id">ID do funcionário</param>
    /// <returns>Dados do funcionário</returns>
    /// <response code="200">Funcionário encontrado</response>
    /// <response code="404">Funcionário não encontrado</response>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(Funcionario), 200)]
    [ProducesResponseType(404)]
    public IActionResult ObterPorId(int id)
    {
        var funcionario = _context.Funcionarios.Find(id);

        if (funcionario == null)
            return NotFound(new { message = $"Funcionário com ID {id} não encontrado." });

        return Ok(funcionario);
    }

    /// <summary>
    /// Cria um novo funcionário
    /// </summary>
    /// <param name="funcionario">Dados do funcionário a ser criado</param>
    /// <returns>Funcionário criado</returns>
    /// <response code="201">Funcionário criado com sucesso</response>
    /// <response code="400">Dados inválidos</response>
    [HttpPost]
    [ProducesResponseType(typeof(Funcionario), 201)]
    [ProducesResponseType(400)]
    public IActionResult Criar([FromBody] Funcionario funcionario)
    {
        if (funcionario == null)
            return BadRequest(new { message = "Dados do funcionário são obrigatórios." });

        if (string.IsNullOrEmpty(funcionario.Nome))
            return BadRequest(new { message = "Nome do funcionário é obrigatório." });

        try
        {
            _context.Funcionarios.Add(funcionario);
            _context.SaveChanges();

            var tableClient = GetTableClient();
            if (tableClient != null)
            {
                var funcionarioLog = new FuncionarioLog(funcionario, TipoAcao.Inclusao, funcionario.Departamento, Guid.NewGuid().ToString());
                tableClient.UpsertEntity(funcionarioLog);
            }

            return CreatedAtAction(nameof(ObterPorId), new { id = funcionario.Id }, funcionario);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro interno do servidor.", details = ex.Message });
        }
    }

    /// <summary>
    /// Atualiza um funcionário existente
    /// </summary>
    /// <param name="id">ID do funcionário</param>
    /// <param name="funcionario">Dados atualizados do funcionário</param>
    /// <returns>Funcionário atualizado</returns>
    /// <response code="200">Funcionário atualizado com sucesso</response>
    /// <response code="400">Dados inválidos</response>
    /// <response code="404">Funcionário não encontrado</response>
    [HttpPut("{id}")]
    [ProducesResponseType(typeof(Funcionario), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(404)]
    public IActionResult Atualizar(int id, [FromBody] Funcionario funcionario)
    {
        if (funcionario == null)
            return BadRequest(new { message = "Dados do funcionário são obrigatórios." });

        var funcionarioBanco = _context.Funcionarios.Find(id);

        if (funcionarioBanco == null)
            return NotFound(new { message = $"Funcionário com ID {id} não encontrado." });

        try
        {
            funcionarioBanco.Nome = funcionario.Nome;
            funcionarioBanco.Endereco = funcionario.Endereco;
            funcionarioBanco.Ramal = funcionario.Ramal;
            funcionarioBanco.EmailProfissional = funcionario.EmailProfissional;
            funcionarioBanco.Departamento = funcionario.Departamento;
            funcionarioBanco.Salario = funcionario.Salario;
            funcionarioBanco.DataAdmissao = funcionario.DataAdmissao;

            _context.Funcionarios.Update(funcionarioBanco);
            _context.SaveChanges();

            var tableClient = GetTableClient();
            if (tableClient != null)
            {
                var funcionarioLog = new FuncionarioLog(funcionarioBanco, TipoAcao.Atualizacao, funcionarioBanco.Departamento, Guid.NewGuid().ToString());
                tableClient.UpsertEntity(funcionarioLog);
            }

            return Ok(funcionarioBanco);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro interno do servidor.", details = ex.Message });
        }
    }

    /// <summary>
    /// Remove um funcionário
    /// </summary>
    /// <param name="id">ID do funcionário</param>
    /// <returns>Confirmação de remoção</returns>
    /// <response code="204">Funcionário removido com sucesso</response>
    /// <response code="404">Funcionário não encontrado</response>
    [HttpDelete("{id}")]
    [ProducesResponseType(204)]
    [ProducesResponseType(404)]
    public IActionResult Deletar(int id)
    {
        var funcionarioBanco = _context.Funcionarios.Find(id);

        if (funcionarioBanco == null)
            return NotFound(new { message = $"Funcionário com ID {id} não encontrado." });

        try
        {
            _context.Funcionarios.Remove(funcionarioBanco);
            _context.SaveChanges();

            var tableClient = GetTableClient();
            if (tableClient != null)
            {
                var funcionarioLog = new FuncionarioLog(funcionarioBanco, TipoAcao.Remocao, funcionarioBanco.Departamento, Guid.NewGuid().ToString());
                tableClient.UpsertEntity(funcionarioLog);
            }

            return NoContent();
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro interno do servidor.", details = ex.Message });
        }
    }
}
