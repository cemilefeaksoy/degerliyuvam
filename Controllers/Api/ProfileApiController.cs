using Degerliyuvam.Services;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers.Api;

[ApiController]
[Route("api/profile")]
public class ProfileApiController : ControllerBase
{
    private readonly AppService _appService;

    public ProfileApiController(AppService appService)
    {
        _appService = appService;
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
            return Unauthorized(new { message = "Kullanici bulunamadi." });
        }

        var dashboard = _appService.GetSellerDashboard(user.Id);
        return Ok(new
        {
            user.Id,
            user.FullName,
            user.Email,
            user.PhoneNumber,
            user.Bio,
            user.ProfileImageUrl,
            user.Role,
            user.IsSellerApproved,
            isSuperAdmin = _appService.IsSuperAdmin(user.Id),
            listingCount = dashboard.TotalListings,
            rentedCount = dashboard.RentedListings
        });
    }

    [HttpPut("me")]
    public IActionResult UpdateMe([FromBody] ProfileUpdateRequest request)
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        try
        {
            _appService.UpdateUserProfile(userId.Value, request.FullName, request.PhoneNumber, request.Bio, request.ProfileImageUrl);

            if (!string.IsNullOrWhiteSpace(request.CurrentPassword) || !string.IsNullOrWhiteSpace(request.NewPassword))
            {
                if (string.IsNullOrWhiteSpace(request.CurrentPassword) || string.IsNullOrWhiteSpace(request.NewPassword))
                {
                    return BadRequest(new { message = "Sifre degisikligi icin mevcut ve yeni sifre gerekir." });
                }

                _appService.ChangeOwnPassword(userId.Value, request.CurrentPassword, request.NewPassword);
            }

            var user = _appService.GetUser(userId.Value)!;
            HttpContext.Session.SetString("UserName", user.FullName);
            HttpContext.Session.SetString("Role", user.Role.ToString());

            return Ok(new { message = "Profil guncellendi." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("seller/{id:int}")]
    public IActionResult Seller(int id)
    {
        var user = _appService.GetUser(id);
        if (user is null)
        {
            return NotFound(new { message = "Satici bulunamadi." });
        }

        var dashboard = _appService.GetSellerDashboard(id);
        return Ok(new
        {
            user.Id,
            user.FullName,
            user.Bio,
            user.ProfileImageUrl,
            user.PhoneNumber,
            user.Role,
            isSuperAdmin = _appService.IsSuperAdmin(user.Id),
            dashboard.TotalListings,
            dashboard.RentedListings,
            dashboard.PendingOffers,
            dashboard.ConversionRate,
            listings = dashboard.MyListings
        });
    }
}

public class ProfileUpdateRequest
{
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Bio { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public string? CurrentPassword { get; set; }
    public string? NewPassword { get; set; }
}
