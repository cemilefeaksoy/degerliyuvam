using Degerliyuvam.Models;
using Degerliyuvam.Services;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers.Api;

[ApiController]
[Route("api/[controller]")]
public class AccountsApiController : ControllerBase
{
    private readonly AppService _appService;

    public AccountsApiController(AppService appService)
    {
        _appService = appService;
    }

    [HttpPost("register")]
    public IActionResult Register([FromBody] RegisterRequest request)
    {
        try
        {
            var user = _appService.Register(request.FullName, request.Email, request.PhoneNumber, request.Password);
            return Ok(new { user.Id, user.FullName, user.Email, user.PhoneNumber, user.Role, user.IsSellerApproved });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("login")]
    public IActionResult Login([FromBody] LoginRequest request)
    {
        var user = _appService.Login(request.Email, request.Password);
        if (user is null) return Unauthorized(new { message = "E-posta veya sifre hatali." });

        return Ok(new { user.Id, user.FullName, user.Email, user.PhoneNumber, user.Role, user.IsSellerApproved });
    }
}

public class RegisterRequest
{
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class LoginRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}
