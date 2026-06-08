using Degerliyuvam.Data;
using Degerliyuvam.Services;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Logging.ClearProviders();
builder.Logging.AddConsole();

builder.Services.AddControllersWithViews();
builder.Services.AddCors(options =>
{
    options.AddPolicy("FlutterClient", policy =>
        policy
            .SetIsOriginAllowed(_ => true)
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials());
});
builder.Services
    .AddDataProtection()
    .SetApplicationName("Degerliyuvam")
    .PersistKeysToFileSystem(new DirectoryInfo(Path.Combine(builder.Environment.ContentRootPath, ".aspnet-data-protection-keys")));
builder.Services.AddSession(options =>
{
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
    options.Cookie.SameSite = SameSiteMode.Lax;
    options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
});
var appDataDir = Path.Combine(builder.Environment.ContentRootPath, "App_Data");
Directory.CreateDirectory(appDataDir);
var dbPath = Path.Combine(appDataDir, "degerliyuvam.db");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite($"Data Source=App_Data/degerliyuvam.db"));
builder.Services.AddScoped<AppService>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();
    _ = scope.ServiceProvider.GetRequiredService<AppService>();
}

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseStaticFiles();

app.UseRouting();
app.UseCors("FlutterClient");
app.UseSession();

app.Use(async (context, next) =>
{
    using var scope = context.RequestServices.CreateScope();
    var appService = scope.ServiceProvider.GetRequiredService<AppService>();

    var hasRemember = context.Request.Cookies.TryGetValue("DegerliyuvamRemember", out var rememberedEmail) ||
                      context.Request.Cookies.TryGetValue("DegerliyuvamRemember", out rememberedEmail);

    if (!context.Session.GetInt32("UserId").HasValue &&
        hasRemember &&
        !string.IsNullOrWhiteSpace(rememberedEmail))
    {
        var user = appService.GetUserByEmail(rememberedEmail);
        if (user is not null)
        {
            context.Session.SetInt32("UserId", user.Id);
            context.Session.SetString("UserName", user.FullName);
            context.Session.SetString("Role", user.Role.ToString());
        }
    }

    var currentUserId = context.Session.GetInt32("UserId");
    if (currentUserId.HasValue)
    {
        var currentUser = appService.GetUser(currentUserId.Value);
        if (currentUser is null)
        {
            context.Session.Clear();
        }
        else
        {
            context.Session.SetString("UserName", currentUser.FullName);
            context.Session.SetString("Role", currentUser.Role.ToString());
        }
    }

    await next();
});

app.UseAuthorization();

app.MapControllers();
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
