using Microsoft.EntityFrameworkCore;
using TrilhaNetAzureDesafio.Context;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddDbContext<RHContext>(options =>
{
    if (builder.Environment.IsDevelopment())
    {
        options.UseSqlite(builder.Configuration.GetConnectionString("ConexaoPadrao"));
    }
    else
    {
        options.UseSqlServer(builder.Configuration.GetConnectionString("ConexaoPadrao"));
    }
});

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "Sistema RH - API de Funcionários",
        Version = "v1",
        Description = "API para gerenciamento de funcionários com logs no Azure Table Storage",
        Contact = new Microsoft.OpenApi.Models.OpenApiContact
        {
            Name = "DIO - Trilha .NET",
            Url = new Uri("https://dio.me")
        }
    });

    // Incluir comentários XML
    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        c.IncludeXmlComments(xmlPath);
    }
});

var app = builder.Build();

// Aplicar migrações automaticamente ao iniciar (se as credenciais permitirem)
using (var scope = app.Services.CreateScope())
{
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    try
    {
        var db = scope.ServiceProvider.GetRequiredService<RHContext>();
        db.Database.Migrate();
        logger.LogInformation("Banco de dados atualizado com sucesso usando migrações EF Core.");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Falha ao aplicar migrações do banco de dados no startup.");
        // Não interrompe a inicialização; permite que a aplicação suba para que o usuário possa inspecionar logs
    }
}

// Swagger
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Sistema RH API v1");
    c.RoutePrefix = "swagger";
    c.DocumentTitle = "Sistema RH - API Documentation";
});

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
