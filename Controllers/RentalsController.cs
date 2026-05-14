using Degerliyuvam.Services;
using Degerliyuvam.ViewModels;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers;

public class RentalsController : Controller
{
    private readonly AppService _appService;

    public RentalsController(AppService appService)
    {
        _appService = appService;
    }

    [HttpGet]
    public IActionResult Payment(int listingId)
    {
        return CreateRentalRequestAndRedirect(listingId);
    }

    [HttpPost]
    public IActionResult Payment(PaymentViewModel model)
    {
        return CreateRentalRequestAndRedirect(model.ListingId);
    }

    [HttpPost]
    public IActionResult RentalRequest(int listingId)
    {
        return CreateRentalRequestAndRedirect(listingId);
    }

    private IActionResult CreateRentalRequestAndRedirect(int listingId)
    {
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue) return RedirectToAction("Login", "Account");

        var listing = _appService.GetListing(listingId);
        if (listing is null) return NotFound();

        try
        {
            _appService.CreateRentalRequest(listingId, userId.Value, string.Empty);
            _appService.SendMessage(
                userId.Value,
                listing.OwnerUserId,
                $"Kiralama talebi: {listing.Title} ilanı kiralanmak isteniyor. Tekliflerim sayfasından kabul veya ret verebilirsiniz.");

            TempData["Success"] = "Kiralama talebiniz satıcıya iletildi. Satıcı kabul ederse ilan kiralandı olarak işaretlenecek.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction("Details", "Listings", new { id = listingId });
    }
}
