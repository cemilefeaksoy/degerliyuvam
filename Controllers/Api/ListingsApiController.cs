using Degerliyuvam.Models;
using Degerliyuvam.Services;
using Degerliyuvam.ViewModels;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers.Api;

[ApiController]
[Route("api/listings")]
public class ListingsApiController : ControllerBase
{
    private readonly AppService _appService;

    public ListingsApiController(AppService appService)
    {
        _appService = appService;
    }

    [HttpGet]
    public IActionResult GetAll(
        [FromQuery] string? city = null,
        [FromQuery] string? purpose = null,
        [FromQuery] decimal? minPrice = null,
        [FromQuery] decimal? maxPrice = null)
    {
        var query = _appService.GetListings().AsEnumerable();

        if (!string.IsNullOrWhiteSpace(city))
        {
            query = query.Where(x =>
                string.Equals(x.Province, city, StringComparison.OrdinalIgnoreCase) ||
                string.Equals(x.City, city, StringComparison.OrdinalIgnoreCase));
        }

        if (!string.IsNullOrWhiteSpace(purpose))
        {
            query = query.Where(x => string.Equals(x.ListingPurpose, purpose, StringComparison.OrdinalIgnoreCase));
        }

        if (minPrice.HasValue)
        {
            query = query.Where(x => x.MonthlyPrice >= minPrice.Value);
        }

        if (maxPrice.HasValue)
        {
            query = query.Where(x => x.MonthlyPrice <= maxPrice.Value);
        }

        return Ok(query.ToList());
    }

    [HttpGet("mine")]
    public IActionResult Mine()
    {
        var userId = CurrentUserId();
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        return Ok(_appService.GetListingsByOwner(userId.Value));
    }

    [HttpGet("{id:int}")]
    public IActionResult GetById(int id)
    {
        var listing = _appService.GetListing(id);
        if (listing is null)
        {
            return NotFound(new { message = "Ilan bulunamadi." });
        }

        var userId = CurrentUserId();
        var isAdmin = IsAdmin();
        var isLoggedIn = userId.HasValue;
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

        return Ok(new
        {
            listing,
            galleryImages = gallery,
            listingRatingAverage = listingRating.average,
            listingRatingCount = listingRating.count,
            sellerRatingAverage = sellerRating.average,
            sellerRatingCount = sellerRating.count,
            comments = _appService.GetCommentsByListing(id).Select(c => new
            {
                c.Id,
                c.ListingId,
                c.AuthorName,
                c.Content,
                c.CreatedAt
            }),
            ratings = _appService.GetRatingsForListing(id),
            offers = isOwner || isAdmin ? _appService.GetOffersForListing(id) : new List<OfferDisplayViewModel>(),
            canEdit = isAdmin || isOwner,
            isAdmin,
            isLoggedIn,
            canRent = isLoggedIn && !isOwner && !listing.IsRented,
            canOffer = isLoggedIn && !isOwner && !listing.IsRented,
            canComment,
            canRate,
            myListingScore = myRating?.ListingScore,
            mySellerScore = myRating?.SellerScore,
            myRatingComment = myRating?.Comment ?? string.Empty,
            owner = _appService.GetUser(listing.OwnerUserId) is { } owner ? new
            {
                owner.Id,
                owner.FullName,
                owner.PhoneNumber,
                owner.Bio,
                owner.ProfileImageUrl,
                owner.Role,
                owner.IsSellerApproved,
                isSuperAdmin = _appService.IsSuperAdmin(owner.Id)
            } : null
        });
    }

    [HttpPost]
    public IActionResult Create([FromBody] ListingUpsertRequest request)
    {
        var userId = CurrentUserId();
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        if (!_appService.CanCreateListing(userId.Value))
        {
            return BadRequest(new { message = "Ilan verebilmek icin admin satıcı onayi bekleniyor." });
        }

        try
        {
            var isAdmin = IsAdmin();
            var ownerId = isAdmin && request.OwnerUserId.HasValue ? request.OwnerUserId.Value : userId.Value;
            var owner = _appService.GetUser(ownerId);
            if (owner is null)
            {
                return BadRequest(new { message = "Ilan sahibi bulunamadi." });
            }

            var gallery = BuildGallery(request);
            if (gallery.Count == 0)
            {
                return BadRequest(new { message = "En az bir ilan fotoğrafı girin." });
            }

            var created = _appService.CreateListing(new Listing
            {
                Title = request.Title,
                Description = request.Description,
                Province = request.Province,
                District = request.District,
                PropertyType = request.PropertyType,
                ListingPurpose = request.ListingPurpose,
                RoomCount = request.RoomCount,
                GrossSquareMeters = request.GrossSquareMeters,
                NetSquareMeters = request.NetSquareMeters,
                BuildingAge = request.BuildingAge,
                Floor = request.Floor,
                TotalFloors = request.TotalFloors,
                BathroomCount = request.BathroomCount,
                HeatingType = request.HeatingType,
                Furnished = request.Furnished,
                Balcony = request.Balcony,
                Elevator = request.Elevator,
                Parking = request.Parking,
                InSite = request.InSite,
                HasPool = request.HasPool,
                MonthlyPrice = request.MonthlyPrice,
                Deposit = request.Deposit,
                Dues = request.Dues,
                ImageUrl = gallery[0],
                ImageGalleryJson = _appService.BuildGalleryJson(gallery),
                OwnerUserId = owner.Id,
                OwnerName = owner.FullName,
                IsAdminRecommended = isAdmin && request.IsAdminRecommended
            });

            return Ok(created);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{id:int}")]
    public IActionResult Update(int id, [FromBody] ListingUpsertRequest request)
    {
        var listing = _appService.GetListing(id);
        if (listing is null)
        {
            return NotFound(new { message = "Ilan bulunamadi." });
        }

        var userId = CurrentUserId();
        var isAdmin = IsAdmin();
        var isOwner = userId.HasValue && userId.Value == listing.OwnerUserId;
        if (!(isAdmin || isOwner))
        {
            return Forbid();
        }

        try
        {
            var gallery = BuildGallery(request);
            if (gallery.Count == 0)
            {
                gallery = _appService.GetListingImageGallery(listing);
            }
            if (gallery.Count == 0)
            {
                return BadRequest(new { message = "En az bir ilan fotoğrafı girin." });
            }

            var ownerId = listing.OwnerUserId;
            if (isAdmin && request.OwnerUserId.HasValue)
            {
                var requestedOwner = _appService.GetUser(request.OwnerUserId.Value);
                if (requestedOwner is null)
                {
                    return BadRequest(new { message = "Ilan sahibi bulunamadi." });
                }

                ownerId = requestedOwner.Id;
                listing.OwnerName = requestedOwner.FullName;
            }

            _appService.UpdateListing(new Listing
            {
                Id = id,
                Title = request.Title,
                Description = request.Description,
                Province = request.Province,
                District = request.District,
                PropertyType = request.PropertyType,
                ListingPurpose = request.ListingPurpose,
                RoomCount = request.RoomCount,
                GrossSquareMeters = request.GrossSquareMeters,
                NetSquareMeters = request.NetSquareMeters,
                BuildingAge = request.BuildingAge,
                Floor = request.Floor,
                TotalFloors = request.TotalFloors,
                BathroomCount = request.BathroomCount,
                HeatingType = request.HeatingType,
                Furnished = request.Furnished,
                Balcony = request.Balcony,
                Elevator = request.Elevator,
                Parking = request.Parking,
                InSite = request.InSite,
                HasPool = request.HasPool,
                MonthlyPrice = request.MonthlyPrice,
                Deposit = request.Deposit,
                Dues = request.Dues,
                ImageUrl = gallery[0],
                ImageGalleryJson = _appService.BuildGalleryJson(gallery),
                OwnerUserId = ownerId,
                OwnerName = listing.OwnerName,
                IsAdminRecommended = isAdmin && request.IsAdminRecommended
            });

            return Ok(_appService.GetListing(id));
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{id:int}")]
    public IActionResult Delete(int id)
    {
        var listing = _appService.GetListing(id);
        if (listing is null)
        {
            return NotFound(new { message = "Ilan bulunamadi." });
        }

        var userId = CurrentUserId();
        var isAdmin = IsAdmin();
        var isOwner = userId.HasValue && userId.Value == listing.OwnerUserId;
        if (!(isAdmin || isOwner))
        {
            return Forbid();
        }

        _appService.DeleteListing(id);
        return Ok(new { message = "Ilan silindi." });
    }

    [HttpPost("{id:int}/offer")]
    public IActionResult CreateOffer(int id, [FromBody] CreateOfferRequest request)
    {
        var userId = CurrentUserId();
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        try
        {
            var offer = _appService.CreateOffer(id, userId.Value, request.Amount, request.Note ?? string.Empty);
            return Ok(offer);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{id:int}/rental-request")]
    public IActionResult CreateRentalRequest(int id, [FromBody] CreateRentalRequestRequest request)
    {
        var userId = CurrentUserId();
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        try
        {
            var offer = _appService.CreateRentalRequest(id, userId.Value, request.CardLast4 ?? string.Empty);
            return Ok(offer);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{id:int}/comment")]
    public IActionResult AddComment(int id, [FromBody] AddCommentRequest request)
    {
        var userId = CurrentUserId();
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        var user = _appService.GetUser(userId.Value);
        if (user is null)
        {
            return Unauthorized(new { message = "Kullanici bulunamadi." });
        }

        try
        {
            return Ok(_appService.AddComment(id, user.FullName, request.Content ?? string.Empty));
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{id:int}/rating")]
    public IActionResult AddRating(int id, [FromBody] AddRatingRequest request)
    {
        var userId = CurrentUserId();
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        try
        {
            _appService.UpsertRating(id, userId.Value, request.ListingScore, request.SellerScore, request.Comment ?? string.Empty);
            return Ok(new { message = "Puan kaydedildi." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{id:int}/toggle-admin-recommendation")]
    public IActionResult ToggleAdminRecommendation(int id)
    {
        if (!IsAdmin())
        {
            return Forbid();
        }

        try
        {
            var value = _appService.ToggleAdminRecommendation(id);
            return Ok(new { isAdminRecommended = value });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{id:int}/toggle-daily-recommendation")]
    public IActionResult ToggleDailyRecommendation(int id)
    {
        if (!IsAdmin())
        {
            return Forbid();
        }

        try
        {
            var value = _appService.ToggleDailyRecommendation(id, 4);
            return Ok(new { isDailyRecommended = value });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private int? CurrentUserId() => HttpContext.Session.GetInt32("UserId");

    private bool IsAdmin() => string.Equals(HttpContext.Session.GetString("Role"), UserRole.Admin.ToString(), StringComparison.OrdinalIgnoreCase);

    private static List<string> BuildGallery(ListingUpsertRequest request)
    {
        var items = new List<string>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        void add(string? value)
        {
            var normalized = (value ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(normalized)) return;
            if (seen.Add(normalized)) items.Add(normalized);
        }

        add(request.ImageUrl);

        if (request.ImageUrls is not null)
        {
            foreach (var item in request.ImageUrls)
            {
                add(item);
            }
        }

        if (!string.IsNullOrWhiteSpace(request.AdditionalImageUrls))
        {
            foreach (var raw in request.AdditionalImageUrls.Split(new[] { '\n', '\r', ',' }, StringSplitOptions.RemoveEmptyEntries))
            {
                add(raw);
            }
        }

        return items;
    }
}

public class ListingUpsertRequest
{
    public int? OwnerUserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Province { get; set; } = string.Empty;
    public string District { get; set; } = string.Empty;
    public string PropertyType { get; set; } = "Daire";
    public string ListingPurpose { get; set; } = "Kiralık";
    public string RoomCount { get; set; } = "2+1";
    public int GrossSquareMeters { get; set; }
    public int NetSquareMeters { get; set; }
    public int BuildingAge { get; set; }
    public int Floor { get; set; }
    public int TotalFloors { get; set; }
    public int BathroomCount { get; set; }
    public string HeatingType { get; set; } = "Kombi Dogalgaz";
    public bool Furnished { get; set; }
    public bool Balcony { get; set; }
    public bool Elevator { get; set; }
    public bool Parking { get; set; }
    public bool InSite { get; set; }
    public bool HasPool { get; set; }
    public decimal MonthlyPrice { get; set; }
    public decimal Deposit { get; set; }
    public decimal Dues { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public List<string> ImageUrls { get; set; } = new();
    public string AdditionalImageUrls { get; set; } = string.Empty;
    public bool IsAdminRecommended { get; set; }
}

public class CreateOfferRequest
{
    public decimal Amount { get; set; }
    public string? Note { get; set; }
}

public class CreateRentalRequestRequest
{
    public string? CardLast4 { get; set; }
}

public class AddCommentRequest
{
    public string? Content { get; set; }
}

public class AddRatingRequest
{
    public int ListingScore { get; set; }
    public int SellerScore { get; set; }
    public string? Comment { get; set; }
}
