using Degerliyuvam.Models;
using Degerliyuvam.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using System.Collections.Concurrent;

namespace Degerliyuvam.Controllers.Api;

[ApiController]
[Route("api/accounts")]
public class AccountsApiController : ControllerBase
{
    private static readonly ConcurrentDictionary<string, PasswordResetEntry> ResetTokens = new();
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
            SetSession(user, request.RememberMe);
            return Ok(new
            {
                user.Id,
                user.FullName,
                user.Email,
                user.PhoneNumber,
                user.Role,
                user.IsSellerApproved,
                isSuperAdmin = _appService.IsSuperAdmin(user.Id)
            });
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

        SetSession(user, request.RememberMe);
        return Ok(new
        {
            user.Id,
            user.FullName,
            user.Email,
            user.PhoneNumber,
            user.Role,
            user.IsSellerApproved,
            isSuperAdmin = _appService.IsSuperAdmin(user.Id)
        });
    }

    [HttpGet("me")]
    public IActionResult Me()
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        var user = _appService.GetUser(userId.Value);
        if (user is null)
        {
            HttpContext.Session.Clear();
            return Unauthorized(new { message = "Oturum gecersiz." });
        }

        return Ok(new
        {
            user.Id,
            user.FullName,
            user.Email,
            user.PhoneNumber,
            user.Role,
            user.Bio,
            user.ProfileImageUrl,
            user.IsSellerApproved,
            isSuperAdmin = _appService.IsSuperAdmin(user.Id)
        });
    }

    [HttpPost("logout")]
    public IActionResult Logout()
    {
        HttpContext.Session.Clear();
        Response.Cookies.Delete("DegerliyuvamRemember");
        return Ok(new { message = "Cikis yapildi." });
    }

    [HttpPost("forgot-password")]
    public IActionResult ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        var user = _appService.GetUserByEmail(request.Email);
        if (user is null)
        {
            return Ok(new { message = "E-posta kayıtlıysa sıfırlama kodu oluşturuldu." });
        }

        var token = Random.Shared.Next(100000, 999999).ToString();
        ResetTokens[token] = new PasswordResetEntry(user.Email, DateTime.UtcNow.AddMinutes(10));

        return Ok(new
        {
            message = "Sıfırlama kodu oluşturuldu. Sınav sürümünde kod ekranda gösterilir.",
            resetCode = token
        });
    }

    [HttpPost("reset-password")]
    public IActionResult ResetPassword([FromBody] ResetPasswordRequest request)
    {
        if (!ResetTokens.TryRemove(request.ResetCode.Trim(), out var entry) ||
            entry.ExpiresAt < DateTime.UtcNow ||
            !string.Equals(entry.Email, request.Email.Trim(), StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new { message = "Sıfırlama kodu geçersiz veya süresi dolmuş." });
        }

        try
        {
            _appService.ResetPassword(request.Email, request.NewPassword);
            return Ok(new { message = "Şifreniz güncellendi." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private void SetSession(User user, bool rememberMe)
    {
        HttpContext.Session.SetInt32("UserId", user.Id);
        HttpContext.Session.SetString("UserName", user.FullName);
        HttpContext.Session.SetString("Role", user.Role.ToString());

        if (!rememberMe)
        {
            Response.Cookies.Delete("DegerliyuvamRemember");
            return;
        }

        Response.Cookies.Append(
            "DegerliyuvamRemember",
            user.Email,
            new CookieOptions
            {
                HttpOnly = true,
                IsEssential = true,
                SameSite = SameSiteMode.Lax,
                Expires = DateTimeOffset.UtcNow.AddDays(180),
                Secure = Request.IsHttps
            });
    }
}

public record PasswordResetEntry(string Email, DateTime ExpiresAt);

public class RegisterRequest
{
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public bool RememberMe { get; set; }
}

public class LoginRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public bool RememberMe { get; set; }
}

public class ForgotPasswordRequest
{
    public string Email { get; set; } = string.Empty;
}

public class ResetPasswordRequest
{
    public string Email { get; set; } = string.Empty;
    public string ResetCode { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}
