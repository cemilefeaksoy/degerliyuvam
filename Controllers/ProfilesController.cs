using Degerliyuvam.Services;
using Degerliyuvam.ViewModels;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers;

public class ProfilesController : Controller
{
    private readonly AppService _appService;
    private readonly IWebHostEnvironment _environment;

    public ProfilesController(AppService appService, IWebHostEnvironment environment)
    {
        _appService = appService;
        _environment = environment;
    }

    [HttpGet]
    public IActionResult Me()
    {
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue) return RedirectToAction("Login", "Account");

        var user = _appService.GetUser(userId.Value);
        if (user is null) return RedirectToAction("Login", "Account");

        return View(new ProfileEditViewModel
        {
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            Bio = user.Bio,
            ProfileImageUrl = user.ProfileImageUrl
        });
    }

    [HttpPost]
    public IActionResult Me(ProfileEditViewModel model)
    {
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue) return RedirectToAction("Login", "Account");

        var wantsPasswordChange =
            !string.IsNullOrWhiteSpace(model.CurrentPassword) ||
            !string.IsNullOrWhiteSpace(model.NewPassword) ||
            !string.IsNullOrWhiteSpace(model.ConfirmNewPassword);

        if (wantsPasswordChange)
        {
            if (string.IsNullOrWhiteSpace(model.CurrentPassword))
            {
                ModelState.AddModelError(nameof(model.CurrentPassword), "Sifre degisikligi icin mevcut sifrenizi girin.");
            }

            if (string.IsNullOrWhiteSpace(model.NewPassword))
            {
                ModelState.AddModelError(nameof(model.NewPassword), "Yeni sifrenizi girin.");
            }
        }

        if (!ModelState.IsValid) return View(model);

        var imagePath = model.ProfileImageUrl?.Trim() ?? string.Empty;
        if (model.ProfileImageFile is not null)
        {
            if (!TrySaveImage(model.ProfileImageFile, out var savedPath, out var error))
            {
                ModelState.AddModelError(nameof(model.ProfileImageFile), error ?? "Profil resmi yuklenemedi.");
                return View(model);
            }

            imagePath = savedPath!;
        }

        if (!string.IsNullOrWhiteSpace(imagePath) && !IsValidImageUrl(imagePath))
        {
            ModelState.AddModelError(nameof(model.ProfileImageUrl), "URL /img ile baslamali veya http/https olmalidir.");
            return View(model);
        }

        if (string.IsNullOrWhiteSpace(imagePath))
        {
            imagePath = "/img/seed-8.jpeg";
        }

        _appService.UpdateUserProfile(userId.Value, model.FullName, model.PhoneNumber, model.Bio, imagePath);
        if (wantsPasswordChange)
        {
            try
            {
                _appService.ChangeOwnPassword(userId.Value, model.CurrentPassword, model.NewPassword);
            }
            catch (Exception ex)
            {
                ModelState.AddModelError(nameof(model.CurrentPassword), ex.Message);
                return View(model);
            }
        }
        HttpContext.Session.SetString("UserName", model.FullName.Trim());

        TempData["Success"] = wantsPasswordChange
            ? "Profiliniz ve sifreniz guncellendi."
            : "Profiliniz guncellendi.";
        return RedirectToAction(nameof(Me));
    }

    [HttpGet]
    public IActionResult Seller(int id)
    {
        var user = _appService.GetUser(id);
        if (user is null) return NotFound();

        var sellerRating = _appService.GetSellerRatingSummary(id);
        var listings = _appService.GetListingsByOwner(id).Take(8).ToList();
        var listingRatingMap = listings.ToDictionary(
            x => x.Id,
            x => _appService.GetListingRatingSummary(x.Id));

        ViewBag.User = user;
        ViewBag.Listings = listings;
        ViewBag.SellerRatingAverage = sellerRating.average;
        ViewBag.SellerRatingCount = sellerRating.count;
        ViewBag.ListingRatingMap = listingRatingMap;
        return View();
    }

    private bool TrySaveImage(IFormFile? file, out string? path, out string? error)
    {
        path = null;
        error = null;

        if (file is null || file.Length == 0)
        {
            error = "Lutfen bir dosya secin.";
            return false;
        }

        const long maxBytes = 8 * 1024 * 1024;
        if (file.Length > maxBytes)
        {
            error = "Resim boyutu en fazla 8 MB olabilir.";
            return false;
        }

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        if (!allowed.Contains(ext))
        {
            error = "Sadece .jpg, .jpeg, .png, .webp dosyalari kabul edilir.";
            return false;
        }

        var uploadsPath = Path.Combine(_environment.WebRootPath, "img", "uploads", "profiles");
        Directory.CreateDirectory(uploadsPath);

        var fileName = $"profile-{Guid.NewGuid():N}{ext}";
        var fullPath = Path.Combine(uploadsPath, fileName);

        using var stream = System.IO.File.Create(fullPath);
        file.CopyTo(stream);

        path = $"/img/uploads/profiles/{fileName}";
        return true;
    }

    private static bool IsValidImageUrl(string value)
    {
        if (value.StartsWith("/img/", StringComparison.OrdinalIgnoreCase)) return true;
        return Uri.TryCreate(value, UriKind.Absolute, out var uri)
            && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps);
    }
}
