using System.Text.Json;
using System.Text;
using System.Globalization;
using Degerliyuvam.Models;
using Degerliyuvam.Services;
using Degerliyuvam.ViewModels;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers;

public class ListingsController : Controller
{
    private readonly AppService _appService;
    private readonly IWebHostEnvironment _environment;

    public ListingsController(AppService appService, IWebHostEnvironment environment)
    {
        _appService = appService;
        _environment = environment;
    }

    public IActionResult Index(
        string? city,
        string? district,
        string? purpose,
        decimal? minPrice,
        decimal? maxPrice,
        string? sort = null,
        bool detailed = false,
        string? room = null,
        string? propertyType = null,
        int? minNet = null,
        int? maxNet = null,
        int? minGross = null,
        int? maxGross = null,
        string? dateFrom = null,
        string? dateTo = null)
    {
        city = (city ?? string.Empty).Trim();
        district = (district ?? string.Empty).Trim();
        purpose = (purpose ?? string.Empty).Trim();

        var locationMap = _appService.GetLocationMap();
        if (string.IsNullOrWhiteSpace(city))
        {
            // Tüm şehirler seciliyken ilce filtresi ilanlari gereksiz daraltmasin.
            district = string.Empty;
        }
        else
        {
            var canonicalCity = locationMap.Keys.FirstOrDefault(k => TextEquals(k, city));
            city = canonicalCity ?? city;
        }

        if (!string.IsNullOrWhiteSpace(city) && locationMap.TryGetValue(city, out var cityDistricts))
        {
            if (!string.IsNullOrWhiteSpace(district) &&
                !cityDistricts.Any(x => TextEquals(x, district)))
            {
                // Invalid district-city pair should not hide all listings.
                district = string.Empty;
            }
        }

        var listings = _appService.GetListings();
        if (!string.IsNullOrWhiteSpace(city))
            listings = listings.Where(x => TextEquals(x.Province, city)).ToList();
        if (!string.IsNullOrWhiteSpace(district))
            listings = listings.Where(x => TextEquals(x.District, district)).ToList();
        if (!string.IsNullOrWhiteSpace(purpose))
            listings = listings.Where(x => TextEquals(x.ListingPurpose, purpose)).ToList();
        if (minPrice.HasValue)
            listings = listings.Where(x => x.MonthlyPrice >= minPrice.Value).ToList();
        if (maxPrice.HasValue)
            listings = listings.Where(x => x.MonthlyPrice <= maxPrice.Value).ToList();

        if (detailed)
        {
            if (!string.IsNullOrWhiteSpace(room))
                listings = listings.Where(x => x.RoomCount.Equals(room, StringComparison.OrdinalIgnoreCase)).ToList();
            if (!string.IsNullOrWhiteSpace(propertyType))
                listings = listings.Where(x => x.PropertyType.Equals(propertyType, StringComparison.OrdinalIgnoreCase)).ToList();
            if (minNet.HasValue)
                listings = listings.Where(x => x.NetSquareMeters >= minNet.Value).ToList();
            if (maxNet.HasValue)
                listings = listings.Where(x => x.NetSquareMeters <= maxNet.Value).ToList();
            if (minGross.HasValue)
                listings = listings.Where(x => x.GrossSquareMeters >= minGross.Value).ToList();
            if (maxGross.HasValue)
                listings = listings.Where(x => x.GrossSquareMeters <= maxGross.Value).ToList();
        }

        if (DateTime.TryParse(dateFrom, out var dfrom))
            listings = listings.Where(x => x.CreatedAt.Date >= dfrom.Date).ToList();
        if (DateTime.TryParse(dateTo, out var dto))
            listings = listings.Where(x => x.CreatedAt.Date <= dto.Date).ToList();

        var hasAnyFilter =
            !string.IsNullOrWhiteSpace(city) ||
            !string.IsNullOrWhiteSpace(district) ||
            !string.IsNullOrWhiteSpace(purpose) ||
            minPrice.HasValue ||
            maxPrice.HasValue ||
            detailed ||
            !string.IsNullOrWhiteSpace(dateFrom) ||
            !string.IsNullOrWhiteSpace(dateTo);

        listings = (sort ?? string.Empty).ToLowerInvariant() switch
        {
            "title_asc" => listings.OrderBy(x => x.Title).ToList(),
            "title_desc" => listings.OrderByDescending(x => x.Title).ToList(),
            "price_asc" => listings.OrderBy(x => x.MonthlyPrice).ToList(),
            "price_desc" => listings.OrderByDescending(x => x.MonthlyPrice).ToList(),
            "newest" => listings.OrderByDescending(x => x.CreatedAt).ToList(),
            "oldest" => listings.OrderBy(x => x.CreatedAt).ToList(),
            _ => hasAnyFilter
                ? listings.OrderByDescending(x => x.CreatedAt).ToList()
                : listings.OrderBy(_ => Guid.NewGuid()).ToList()
        };

        ViewBag.FilterDateFrom = dateFrom;
        ViewBag.FilterDateTo = dateTo;
        ViewBag.Cities = OrderCitiesForUi(locationMap.Keys);
        ViewBag.Districts = !string.IsNullOrWhiteSpace(city) && locationMap.TryGetValue(city, out var filteredDistricts)
            ? filteredDistricts.OrderBy(x => x).ToList()
            : locationMap.Values.SelectMany(x => x).Distinct().OrderBy(x => x).ToList();
        ViewBag.LocationMapJson = JsonSerializer.Serialize(locationMap);

        var all = _appService.GetListings();
        ViewBag.Rooms = all.Select(x => x.RoomCount).Distinct().OrderBy(x => x).ToList();
        ViewBag.Types = all.Select(x => x.PropertyType).Distinct().OrderBy(x => x).ToList();

        ViewBag.FilterCity = city;
        ViewBag.FilterDistrict = district;
        ViewBag.FilterPurpose = purpose;
        ViewBag.FilterMinPrice = minPrice;
        ViewBag.FilterMaxPrice = maxPrice;
        ViewBag.FilterDetailed = detailed;
        ViewBag.FilterRoom = room;
        ViewBag.FilterType = propertyType;
        ViewBag.FilterMinNet = minNet;
        ViewBag.FilterMaxNet = maxNet;
        ViewBag.FilterMinGross = minGross;
        ViewBag.FilterMaxGross = maxGross;
        ViewBag.FilterSort = sort;
        ViewBag.DailyRecommended = GetDailyRecommendedListings();
        ViewBag.ListingPageTitle = "İlan Ara & Filtrele";
        ViewBag.ListingPageCountLabel = "ilan bulundu";

        return View(listings);
    }

    private static List<string> OrderCitiesForUi(IEnumerable<string> cities)
    {
        var priority = new[] { "Istanbul", "Ankara", "Antalya", "Izmir" };
        var remaining = cities
            .Where(c => !priority.Contains(c, StringComparer.OrdinalIgnoreCase))
            .OrderBy(c => c)
            .ToList();

        var ordered = priority.Where(p => cities.Contains(p, StringComparer.OrdinalIgnoreCase)).ToList();
        ordered.AddRange(remaining);
        return ordered;
    }

    private List<Listing> GetDailyRecommendedListings()
    {
        return _appService.GetListings()
            .Where(x => x.IsDailyRecommended && !x.IsRented)
            .OrderByDescending(x => x.CreatedAt)
            .Take(4)
            .ToList();
    }

    private static bool TextEquals(string? left, string? right)
        => NormalizeForCompare(left) == NormalizeForCompare(right);

    private static string NormalizeForCompare(string? value)
    {
        var s = (value ?? string.Empty).Trim().ToLowerInvariant();
        if (s.Length == 0) return string.Empty;

        s = s
            .Replace('ı', 'i')
            .Replace('ş', 's')
            .Replace('ğ', 'g')
            .Replace('ü', 'u')
            .Replace('ö', 'o')
            .Replace('ç', 'c');

        var normalized = s.Normalize(NormalizationForm.FormD);
        var chars = normalized.Where(c => CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark).ToArray();
        return new string(chars);
    }

    [HttpGet]
    public IActionResult MyListings()
    {
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue) return RedirectToAction("Login", "Account");

        var myListings = _appService.GetListingsByOwner(userId.Value)
            .OrderByDescending(x => x.CreatedAt)
            .ToList();

        PrepareListingIndexViewData();
        ViewBag.ListingPageTitle = "Kendi İlanlarım";
        ViewBag.ListingPageCountLabel = "ilanınız";
        ViewBag.IsMyListings = true;

        return View("Index", myListings);
    }

    [HttpGet]
    public IActionResult Rented()
    {
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue) return RedirectToAction("Login", "Account");

        var rentedListings = _appService.GetListingsRentedByUser(userId.Value);

        PrepareListingIndexViewData();
        ViewBag.ListingPageTitle = "Kiraladığım İlanlar";
        ViewBag.ListingPageCountLabel = "kiraladığınız ilan";
        ViewBag.IsRentedListings = true;

        return View("Index", rentedListings);
    }

    private void PrepareListingIndexViewData()
    {
        var locationMap = _appService.GetLocationMap();
        ViewBag.Cities = OrderCitiesForUi(locationMap.Keys);
        ViewBag.Districts = locationMap.Values.SelectMany(x => x).Distinct().OrderBy(x => x).ToList();
        ViewBag.LocationMapJson = JsonSerializer.Serialize(locationMap);

        var all = _appService.GetListings();
        ViewBag.Rooms = all.Select(x => x.RoomCount).Distinct().OrderBy(x => x).ToList();
        ViewBag.Types = all.Select(x => x.PropertyType).Distinct().OrderBy(x => x).ToList();
        ViewBag.FilterSort = string.Empty;
        ViewBag.FilterDetailed = false;
        ViewBag.DailyRecommended = new List<Listing>();
    }

    public IActionResult Details(int id)
    {
        var listing = _appService.GetListing(id);
        if (listing is null)
        {
            return NotFound();
        }

        var userId = AuthSession.UserId(this);
        var isAdmin = AuthSession.IsAdmin(this);
        var isLoggedIn = AuthSession.IsLoggedIn(this);
        var isOwner = userId.HasValue && userId.Value == listing.OwnerUserId;
        var canComment = userId.HasValue && _appService.HasUserRentedListing(id, userId.Value);
        var canRate = userId.HasValue && _appService.CanUserRateListing(id, userId.Value);
        var myRating = userId.HasValue ? _appService.GetUserRating(id, userId.Value) : null;
        var listingRating = _appService.GetListingRatingSummary(id);
        var sellerRating = _appService.GetSellerRatingSummary(listing.OwnerUserId);
        var gallery = _appService.GetListingImageGallery(listing);
        if (!gallery.Any())
        {
            gallery.Add(string.IsNullOrWhiteSpace(listing.ImageUrl) ? "/img/seed-1.jpeg" : listing.ImageUrl);
        }

        var vm = new ListingDetailsViewModel
        {
            Listing = listing,
            GalleryImages = gallery,
            OwnerUser = _appService.GetUser(listing.OwnerUserId),
            Comments = _appService.GetCommentsByListing(id),
            Ratings = _appService.GetRatingsForListing(id),
            Offers = isOwner || isAdmin ? _appService.GetOffersForListing(id) : new List<OfferDisplayViewModel>(),
            IsAdmin = isAdmin,
            IsLoggedIn = isLoggedIn,
            CanEdit = isAdmin || isOwner,
            CanRent = isLoggedIn && !isOwner && !listing.IsRented,
            CanOffer = isLoggedIn && !isOwner && !listing.IsRented,
            CanComment = canComment,
            CanRate = canRate,
            ListingRatingAverage = listingRating.average,
            ListingRatingCount = listingRating.count,
            SellerRatingAverage = sellerRating.average,
            SellerRatingCount = sellerRating.count,
            MyListingScore = myRating?.ListingScore,
            MySellerScore = myRating?.SellerScore,
            MyRatingComment = myRating?.Comment ?? string.Empty
        };

        return View(vm);
    }

    [HttpGet]
    public IActionResult Create()
    {
        if (!AuthSession.IsLoggedIn(this)) return RedirectToAction("Login", "Account");
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue || _appService.GetUser(userId.Value) is null)
        {
            AuthSession.SignOut(this);
            return RedirectToAction("Login", "Account");
        }

        if (userId.HasValue && !_appService.CanCreateListing(userId.Value))
        {
            TempData["Error"] = "İlan verebilmek icin admin satıcı onayi bekleniyor.";
            return RedirectToAction(nameof(Index));
        }

        SetLocationViewData();
        ViewBag.IsAdmin = AuthSession.IsAdmin(this);
        SetOwnerViewData();

        return View(new ListingEditViewModel
        {
            Title = "Yeni İlan",
            Description = "İlan açıklaması daha sonra güncellenebilir.",
            Province = "Istanbul",
            District = "Besiktas",
            PropertyType = "Daire",
            ListingPurpose = "Kiralık",
            RoomCount = "2+1",
            GrossSquareMeters = 120,
            NetSquareMeters = 95,
            BuildingAge = 3,
            Floor = 4,
            TotalFloors = 10,
            BathroomCount = 2,
            HeatingType = "Kombi Dogalgaz",
            MonthlyPrice = 30000,
            Deposit = 50000,
            Dues = 1800,
            Balcony = true,
            Elevator = true,
            Parking = true,
            InSite = true,
            ImageUrl = string.Empty,
            OwnerUserId = userId
        });
    }

    [HttpPost]
    public IActionResult Create(ListingEditViewModel model)
    {
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue) return RedirectToAction("Login", "Account");
        if (_appService.GetUser(userId.Value) is null)
        {
            AuthSession.SignOut(this);
            return RedirectToAction("Login", "Account");
        }
        if (!_appService.CanCreateListing(userId.Value))
        {
            TempData["Error"] = "İlan verebilmek icin admin satıcı onayi bekleniyor.";
            return RedirectToAction(nameof(Index));
        }

        SetLocationViewData();
        ViewBag.IsAdmin = AuthSession.IsAdmin(this);
        SetOwnerViewData();

        model.ImageUrl = model.ImageUrl?.Trim() ?? string.Empty;
        model.AdditionalImageUrls = model.AdditionalImageUrls?.Trim() ?? string.Empty;
        ApplyCreateDefaults(model);

        model.TermsAccepted = true;
        ModelState.Clear();

        var gallery = new List<string>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        void addImage(string value)
        {
            var normalized = value.Trim();
            if (seen.Add(normalized))
            {
                gallery.Add(normalized);
            }
        }

        if (model.ImageFile is not null && model.ImageFile.Length > 0)
        {
            if (!TrySaveImage(model.ImageFile, out var savedPath, out var error))
            {
                savedPath = null;
            }
            else if (!string.IsNullOrWhiteSpace(savedPath))
            {
                addImage(savedPath);
            }
        }

        if (!string.IsNullOrWhiteSpace(model.ImageUrl))
        {
            if (!IsValidImageUrl(model.ImageUrl))
            {
                model.ImageUrl = string.Empty;
            }
            else
            {
                addImage(model.ImageUrl);
            }
        }

        if (model.ImageFiles is not null)
        {
            foreach (var file in model.ImageFiles.Where(f => f is not null && f.Length > 0))
            {
                if (!TrySaveImage(file, out var savedPath, out var error))
                {
                    continue;
                }
                if (!string.IsNullOrWhiteSpace(savedPath))
                {
                    addImage(savedPath);
                }
            }
        }

        foreach (var url in ParseAdditionalImageUrls(model.AdditionalImageUrls))
        {
            if (!IsValidImageUrl(url))
            {
                continue;
            }
            addImage(url);
        }

        if (gallery.Count == 0)
        {
            ModelState.AddModelError(nameof(model.ImageFile), "Lütfen en az bir ilan fotoğrafı seçin veya geçerli bir fotoğraf URL'si girin.");
        }

        if (!ModelState.IsValid) return View(model);

        var imagePath = gallery[0];

        var isAdmin = AuthSession.IsAdmin(this);
        var selectedOwnerId = userId.Value;
        if (isAdmin)
        {
            if (!model.OwnerUserId.HasValue)
            {
                model.OwnerUserId = userId.Value;
            }

            var selectedOwner = _appService.GetUser(model.OwnerUserId.Value);
            if (selectedOwner is null)
            {
                ModelState.AddModelError(nameof(model.OwnerUserId), "İlan sahibi bulunamadi.");
                return View(model);
            }

            selectedOwnerId = selectedOwner.Id;
        }

        var ownerUser = _appService.GetUser(selectedOwnerId);
        if (ownerUser is null)
        {
            ModelState.AddModelError(string.Empty, "İlan sahibi bulunamadi.");
            return View(model);
        }

        var listing = _appService.CreateListing(new Listing
        {
            Title = model.Title,
            Description = model.Description,
            Province = model.Province,
            District = model.District,
            PropertyType = model.PropertyType,
            ListingPurpose = model.ListingPurpose,
            RoomCount = model.RoomCount,
            GrossSquareMeters = model.GrossSquareMeters,
            NetSquareMeters = model.NetSquareMeters,
            BuildingAge = model.BuildingAge,
            Floor = model.Floor,
            TotalFloors = model.TotalFloors,
            BathroomCount = model.BathroomCount,
            HeatingType = model.HeatingType,
            Furnished = model.Furnished,
            Balcony = model.Balcony,
            Elevator = model.Elevator,
            Parking = model.Parking,
            InSite = model.InSite,
            HasPool = model.HasPool,
            MonthlyPrice = model.MonthlyPrice,
            Deposit = model.Deposit,
            Dues = model.Dues,
            ImageUrl = imagePath,
            ImageGalleryJson = _appService.BuildGalleryJson(gallery),
            OwnerUserId = selectedOwnerId,
            OwnerName = ownerUser.FullName,
            IsAdminRecommended = isAdmin && model.IsAdminRecommended
        });

        TempData["Success"] = "İlanınız başarıyla yayına alındı.";
        return RedirectToAction(nameof(Details), new { id = listing.Id });
    }

    [HttpGet]
    public IActionResult Edit(int id)
    {
        var listing = _appService.GetListing(id);
        if (listing is null) return NotFound();

        var userId = AuthSession.UserId(this);
        var isAdmin = AuthSession.IsAdmin(this);
        if (!(isAdmin || (userId.HasValue && userId.Value == listing.OwnerUserId))) return Forbid();

        SetLocationViewData();
        ViewBag.IsAdmin = isAdmin;
        SetOwnerViewData();

        return View(new ListingEditViewModel
        {
            Id = listing.Id,
            Title = listing.Title,
            Description = listing.Description,
            Province = listing.Province,
            District = listing.District,
            PropertyType = listing.PropertyType,
            ListingPurpose = listing.ListingPurpose,
            RoomCount = listing.RoomCount,
            GrossSquareMeters = listing.GrossSquareMeters,
            NetSquareMeters = listing.NetSquareMeters,
            BuildingAge = listing.BuildingAge,
            Floor = listing.Floor,
            TotalFloors = listing.TotalFloors,
            BathroomCount = listing.BathroomCount,
            HeatingType = listing.HeatingType,
            Furnished = listing.Furnished,
            Balcony = listing.Balcony,
            Elevator = listing.Elevator,
            Parking = listing.Parking,
            InSite = listing.InSite,
            HasPool = listing.HasPool,
            MonthlyPrice = listing.MonthlyPrice,
            Deposit = listing.Deposit,
            Dues = listing.Dues,
            ImageUrl = listing.ImageUrl,
            CoverImageUrl = listing.ImageUrl,
            OwnerUserId = listing.OwnerUserId,
            ExistingImagesCsv = string.Join(",", _appService.GetListingImageGallery(listing)),
            IsAdminRecommended = listing.IsAdminRecommended
        });
    }

    [HttpPost]
    public IActionResult Edit(ListingEditViewModel model)
    {
        var listing = _appService.GetListing(model.Id);
        if (listing is null) return NotFound();

        var userId = AuthSession.UserId(this);
        var isAdmin = AuthSession.IsAdmin(this);
        if (!(isAdmin || (userId.HasValue && userId.Value == listing.OwnerUserId))) return Forbid();

        SetLocationViewData();
        ViewBag.IsAdmin = isAdmin;
        SetOwnerViewData();

        model.ImageUrl = model.ImageUrl?.Trim() ?? string.Empty;
        model.AdditionalImageUrls = model.AdditionalImageUrls?.Trim() ?? string.Empty;
        model.ExistingImagesCsv = model.ExistingImagesCsv?.Trim() ?? string.Empty;
        ApplyEditDefaults(model, listing);

        var gallery = model.ResetExistingImages
            ? new List<string>()
            : ParseExistingImages(model.ExistingImagesCsv);

        if (gallery.Count == 0 && !model.ResetExistingImages)
        {
            gallery = _appService.GetListingImageGallery(listing);
        }

        var seen = new HashSet<string>(gallery, StringComparer.OrdinalIgnoreCase);
        void addImage(string value)
        {
            var normalized = value.Trim();
            if (seen.Add(normalized))
            {
                gallery.Add(normalized);
            }
        }

        var requestedCover = (model.CoverImageUrl ?? string.Empty).Trim();

        if (!string.IsNullOrWhiteSpace(model.ImageUrl))
        {
            if (!IsValidImageUrl(model.ImageUrl))
            {
                ModelState.AddModelError(nameof(model.ImageUrl), "URL /img ile baslamali veya http/https olmalidir.");
            }
            else
            {
                addImage(model.ImageUrl);
            }
        }

        foreach (var url in ParseAdditionalImageUrls(model.AdditionalImageUrls))
        {
            if (!IsValidImageUrl(url))
            {
                ModelState.AddModelError(nameof(model.AdditionalImageUrls), $"Gecersiz gorsel URL: {url}");
                continue;
            }
            addImage(url);
        }

        if (model.ImageFile is not null && model.ImageFile.Length > 0)
        {
            if (!TrySaveImage(model.ImageFile, out var savedPath, out var error))
            {
                ModelState.AddModelError(nameof(model.ImageFile), error ?? "Resim yuklenemedi.");
            }
            else if (!string.IsNullOrWhiteSpace(savedPath))
            {
                addImage(savedPath);
                requestedCover = savedPath;
            }
        }

        if (model.ImageFiles is not null)
        {
            foreach (var file in model.ImageFiles.Where(f => f is not null && f.Length > 0))
            {
                if (!TrySaveImage(file, out var savedPath, out var error))
                {
                    ModelState.AddModelError(nameof(model.ImageFiles), error ?? "Resim yuklenemedi.");
                    continue;
                }
                if (!string.IsNullOrWhiteSpace(savedPath))
                {
                    addImage(savedPath);
                }
            }
        }

        if (gallery.Count == 0)
        {
            ModelState.AddModelError(nameof(model.ImageFile), "En az bir ilan gorseli ekleyin.");
        }

        if (!string.IsNullOrWhiteSpace(requestedCover) && gallery.Remove(requestedCover))
        {
            gallery.Insert(0, requestedCover);
        }

        model.ExistingImagesCsv = string.Join(",", gallery);

        if (!ModelState.IsValid) return View(model);

        var imagePath = gallery[0];

        _appService.UpdateListing(new Listing
        {
            Id = model.Id,
            Title = model.Title,
            Description = model.Description,
            Province = model.Province,
            District = model.District,
            PropertyType = model.PropertyType,
            ListingPurpose = model.ListingPurpose,
            RoomCount = model.RoomCount,
            GrossSquareMeters = model.GrossSquareMeters,
            NetSquareMeters = model.NetSquareMeters,
            BuildingAge = model.BuildingAge,
            Floor = model.Floor,
            TotalFloors = model.TotalFloors,
            BathroomCount = model.BathroomCount,
            HeatingType = model.HeatingType,
            Furnished = model.Furnished,
            Balcony = model.Balcony,
            Elevator = model.Elevator,
            Parking = model.Parking,
            InSite = model.InSite,
            HasPool = model.HasPool,
            MonthlyPrice = model.MonthlyPrice,
            Deposit = model.Deposit,
            Dues = model.Dues,
            ImageUrl = imagePath,
            ImageGalleryJson = _appService.BuildGalleryJson(gallery),
            IsAdminRecommended = isAdmin && model.IsAdminRecommended
        });

        TempData["Success"] = "İlan guncellendi.";
        return RedirectToAction(nameof(Details), new { id = model.Id });
    }

    [HttpPost]
    public IActionResult Delete(int id)
    {
        var listing = _appService.GetListing(id);
        if (listing is null) return NotFound();

        var userId = AuthSession.UserId(this);
        if (!(AuthSession.IsAdmin(this) || (userId.HasValue && userId.Value == listing.OwnerUserId))) return Forbid();

        _appService.DeleteListing(id);
        TempData["Success"] = "İlan silindi.";
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public IActionResult AddComment(int listingId, string content)
    {
        if (!AuthSession.IsLoggedIn(this)) return RedirectToAction("Login", "Account");
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue) return RedirectToAction("Login", "Account");

        if (!_appService.HasUserRentedListing(listingId, userId.Value))
        {
            TempData["Error"] = "Yorum yazabilmek icin bu ilani kiralamis olmaniz gerekir.";
            return RedirectToAction(nameof(Details), new { id = listingId });
        }

        if (!string.IsNullOrWhiteSpace(content))
        {
            _appService.AddComment(listingId, AuthSession.UserName(this) ?? "Müşteri", content.Trim());
        }

        return RedirectToAction(nameof(Details), new { id = listingId });
    }

    [HttpPost]
    public IActionResult AddRating(RatingCreateViewModel model)
    {
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue) return RedirectToAction("Login", "Account");

        try
        {
            _appService.UpsertRating(model.ListingId, userId.Value, model.ListingScore, model.SellerScore, model.Comment);
            TempData["Success"] = "Puaniniz kaydedildi.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction(nameof(Details), new { id = model.ListingId });
    }

    [HttpPost]
    public IActionResult CreateOffer(OfferCreateViewModel model)
    {
        var fromUserId = AuthSession.UserId(this);
        if (!fromUserId.HasValue) return RedirectToAction("Login", "Account");

        try
        {
            var offer = _appService.CreateOffer(model.ListingId, fromUserId.Value, model.Amount, model.Note);
            var listing = _appService.GetListing(model.ListingId);

            if (listing is not null)
            {
                _appService.SendMessage(fromUserId.Value, listing.OwnerUserId,
                    $"Yeni teklif geldi: {listing.Title} icin {model.Amount:N0} TL teklif verildi.",
                    offerId: offer.Id);
            }

            TempData["Success"] = "Teklifiniz satıcıya iletildi.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction(nameof(Details), new { id = model.ListingId });
    }

    [HttpPost]
    public IActionResult ToggleAdminRecommendation(int id)
    {
        if (!AuthSession.IsAdmin(this)) return Forbid();

        try
        {
            var value = _appService.ToggleAdminRecommendation(id);
            TempData["Success"] = value
                ? "İlan admin önerisi olarak isaretlendi."
                : "İlan admin önerisi isareti kaldirildi.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }

        var referer = Request.Headers.Referer.ToString();
        if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);
        return RedirectToAction(nameof(Details), new { id });
    }

    [HttpPost]
    public IActionResult ToggleDailyRecommendation(int id)
    {
        if (!AuthSession.IsAdmin(this)) return Forbid();

        try
        {
            var value = _appService.ToggleDailyRecommendation(id, 4);
            TempData["Success"] = value
                ? "İlan gunun tavsiye edilen evlerine eklendi."
                : "İlan gunun tavsiye edilen evlerinden kaldirildi.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }

        var referer = Request.Headers.Referer.ToString();
        if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);
        return RedirectToAction(nameof(Details), new { id });
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

        var uploadsPath = Path.Combine(_environment.WebRootPath, "img", "uploads");
        Directory.CreateDirectory(uploadsPath);

        var fileName = $"listing-{Guid.NewGuid():N}{ext}";
        var fullPath = Path.Combine(uploadsPath, fileName);

        using var stream = System.IO.File.Create(fullPath);
        file.CopyTo(stream);

        path = $"/img/uploads/{fileName}";
        return true;
    }

    private void SetLocationViewData()
    {
        var map = _appService.GetLocationMap();
        ViewBag.Provinces = OrderCitiesForUi(map.Keys);
        ViewBag.LocationMapJson = JsonSerializer.Serialize(map);
    }

    private void SetOwnerViewData()
    {
        ViewBag.Sellers = _appService.GetUsers();
    }

    private void ApplyCreateDefaults(ListingEditViewModel model)
    {
        model.Title = string.IsNullOrWhiteSpace(model.Title) ? "Yeni İlan" : model.Title.Trim();
        model.Description = string.IsNullOrWhiteSpace(model.Description) ? "İlan açıklaması daha sonra güncellenebilir." : model.Description.Trim();
        model.Province = string.IsNullOrWhiteSpace(model.Province) ? "Istanbul" : model.Province.Trim();
        model.District = string.IsNullOrWhiteSpace(model.District) ? "Besiktas" : model.District.Trim();
        model.PropertyType = string.IsNullOrWhiteSpace(model.PropertyType) ? "Daire" : model.PropertyType.Trim();
        model.ListingPurpose = string.IsNullOrWhiteSpace(model.ListingPurpose) ? "Kiralık" : model.ListingPurpose.Trim();
        model.RoomCount = string.IsNullOrWhiteSpace(model.RoomCount) ? "2+1" : model.RoomCount.Trim();
        model.GrossSquareMeters = model.GrossSquareMeters <= 0 ? 120 : model.GrossSquareMeters;
        model.NetSquareMeters = model.NetSquareMeters <= 0 ? 95 : model.NetSquareMeters;
        model.BuildingAge = model.BuildingAge < 0 ? 0 : model.BuildingAge;
        model.Floor = model.Floor < 0 ? 0 : model.Floor;
        model.TotalFloors = model.TotalFloors <= 0 ? 10 : model.TotalFloors;
        model.BathroomCount = model.BathroomCount <= 0 ? 1 : model.BathroomCount;
        model.HeatingType = string.IsNullOrWhiteSpace(model.HeatingType) ? "Kombi Dogalgaz" : model.HeatingType.Trim();
        model.MonthlyPrice = model.MonthlyPrice < 1000 ? 25000 : model.MonthlyPrice;
        model.Deposit = model.Deposit < 0 ? 0 : model.Deposit;
        model.Dues = model.Dues < 0 ? 0 : model.Dues;
        ModelState.Remove(nameof(ListingEditViewModel.Title));
        ModelState.Remove(nameof(ListingEditViewModel.Description));
        ModelState.Remove(nameof(ListingEditViewModel.TermsAccepted));
        ClearAdvancedValidation();
    }

    private void ApplyEditDefaults(ListingEditViewModel model, Listing listing)
    {
        model.Province = string.IsNullOrWhiteSpace(model.Province) ? listing.Province : model.Province.Trim();
        model.District = string.IsNullOrWhiteSpace(model.District) ? listing.District : model.District.Trim();
        model.PropertyType = string.IsNullOrWhiteSpace(model.PropertyType) ? listing.PropertyType : model.PropertyType.Trim();
        model.ListingPurpose = string.IsNullOrWhiteSpace(model.ListingPurpose) ? listing.ListingPurpose : model.ListingPurpose.Trim();
        model.RoomCount = string.IsNullOrWhiteSpace(model.RoomCount) ? listing.RoomCount : model.RoomCount.Trim();
        model.GrossSquareMeters = model.GrossSquareMeters <= 0 ? listing.GrossSquareMeters : model.GrossSquareMeters;
        model.NetSquareMeters = model.NetSquareMeters <= 0 ? listing.NetSquareMeters : model.NetSquareMeters;
        model.BuildingAge = model.BuildingAge < 0 ? listing.BuildingAge : model.BuildingAge;
        model.Floor = model.Floor < 0 ? listing.Floor : model.Floor;
        model.TotalFloors = model.TotalFloors <= 0 ? listing.TotalFloors : model.TotalFloors;
        model.BathroomCount = model.BathroomCount <= 0 ? listing.BathroomCount : model.BathroomCount;
        model.HeatingType = string.IsNullOrWhiteSpace(model.HeatingType) ? listing.HeatingType : model.HeatingType.Trim();
        model.MonthlyPrice = model.MonthlyPrice < 1000 ? listing.MonthlyPrice : model.MonthlyPrice;
        model.Deposit = model.Deposit < 0 ? listing.Deposit : model.Deposit;
        model.Dues = model.Dues < 0 ? listing.Dues : model.Dues;
        ClearAdvancedValidation();
    }

    private void ClearAdvancedValidation()
    {
        ModelState.Remove(nameof(ListingEditViewModel.Province));
        ModelState.Remove(nameof(ListingEditViewModel.District));
        ModelState.Remove(nameof(ListingEditViewModel.PropertyType));
        ModelState.Remove(nameof(ListingEditViewModel.ListingPurpose));
        ModelState.Remove(nameof(ListingEditViewModel.RoomCount));
        ModelState.Remove(nameof(ListingEditViewModel.GrossSquareMeters));
        ModelState.Remove(nameof(ListingEditViewModel.NetSquareMeters));
        ModelState.Remove(nameof(ListingEditViewModel.BuildingAge));
        ModelState.Remove(nameof(ListingEditViewModel.Floor));
        ModelState.Remove(nameof(ListingEditViewModel.TotalFloors));
        ModelState.Remove(nameof(ListingEditViewModel.BathroomCount));
        ModelState.Remove(nameof(ListingEditViewModel.HeatingType));
        ModelState.Remove(nameof(ListingEditViewModel.MonthlyPrice));
        ModelState.Remove(nameof(ListingEditViewModel.Deposit));
        ModelState.Remove(nameof(ListingEditViewModel.Dues));
    }

    private static bool IsValidImageUrl(string value)
    {
        if (value.StartsWith("/img/", StringComparison.OrdinalIgnoreCase)) return true;
        return Uri.TryCreate(value, UriKind.Absolute, out var uri)
            && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps);
    }

    private static List<string> ParseAdditionalImageUrls(string value)
    {
        if (string.IsNullOrWhiteSpace(value)) return new List<string>();

        return value
            .Split(new char[] { '\n', '\r', ',', ';' }, StringSplitOptions.RemoveEmptyEntries)
            .Select(x => x.Trim())
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static List<string> ParseExistingImages(string csv)
    {
        if (string.IsNullOrWhiteSpace(csv)) return new List<string>();

        return csv
            .Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
            .Select(x => x.Trim())
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }
}
