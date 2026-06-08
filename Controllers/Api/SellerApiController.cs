using Degerliyuvam.Models;
using Degerliyuvam.Services;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers.Api;

[ApiController]
[Route("api/seller")]
public class SellerApiController : ControllerBase
{
    private readonly AppService _appService;

    public SellerApiController(AppService appService)
    {
        _appService = appService;
    }

    [HttpGet("dashboard")]
    public IActionResult Dashboard()
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        return Ok(_appService.GetSellerDashboard(userId.Value));
    }

    [HttpGet("offers")]
    public IActionResult Offers()
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        return Ok(_appService.GetIncomingOffers(userId.Value));
    }

    [HttpPost("offers/{offerId:int}")]
    public IActionResult UpdateOfferStatus(int offerId, [FromBody] UpdateOfferRequest request)
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        try
        {
            var offer = _appService.UpdateOfferStatus(userId.Value, offerId, request.Status);
            return Ok(offer);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

public class UpdateOfferRequest
{
    public OfferStatus Status { get; set; }
}
