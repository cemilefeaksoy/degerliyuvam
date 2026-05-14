using Degerliyuvam.Models;
using Degerliyuvam.Services;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers;

public class SellerController : Controller
{
    private readonly AppService _appService;

    public SellerController(AppService appService)
    {
        _appService = appService;
    }

    public IActionResult Dashboard()
    {
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue) return RedirectToAction("Login", "Account");

        var vm = _appService.GetSellerDashboard(userId.Value);
        return View(vm);
    }

    [HttpGet]
    public IActionResult Offers()
    {
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue) return RedirectToAction("Login", "Account");

        var offers = _appService.GetIncomingOffers(userId.Value);
        return View(offers);
    }

    [HttpPost]
    public IActionResult UpdateOfferStatus(int offerId, OfferStatus status, string? returnTo = null)
    {
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue) return RedirectToAction("Login", "Account");

        try
        {
            var offer = _appService.UpdateOfferStatus(userId.Value, offerId, status);
            var listing = _appService.GetListing(offer.ListingId);

            if (listing is not null)
            {
                var statusText = status == OfferStatus.Accepted ? "kabul edildi" : "reddedildi";
                var prefix = offer.Type == OfferType.RentalRequest ? "Kiralama talebiniz" : "Teklifiniz";
                _appService.SendMessage(userId.Value, offer.FromUserId, $"{listing.Title} için {prefix} {statusText}.");
            }

            if (status == OfferStatus.Accepted && offer.Type == OfferType.RentalRequest)
            {
                TempData["Success"] = "Kiralama talebi kabul edildi. İlan kiralandı olarak işaretlendi.";
            }
            else
            {
                TempData["Success"] = status == OfferStatus.Accepted ? "Teklif kabul edildi." : "Teklif reddedildi.";
            }
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }

        return string.Equals(returnTo, nameof(Offers), StringComparison.OrdinalIgnoreCase)
            ? RedirectToAction(nameof(Offers))
            : RedirectToAction(nameof(Dashboard));
    }
}
