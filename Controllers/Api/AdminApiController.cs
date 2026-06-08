using Degerliyuvam.Models;
using Degerliyuvam.Services;
using Degerliyuvam.ViewModels;
using Microsoft.AspNetCore.Mvc;
using System.Globalization;
using System.Text;

namespace Degerliyuvam.Controllers.Api;

[ApiController]
[Route("api/admin")]
public class AdminApiController : ControllerBase
{
    private readonly AppService _appService;

    public AdminApiController(AppService appService)
    {
        _appService = appService;
    }

    [HttpGet("dashboard")]
    public IActionResult Dashboard()
    {
        if (!IsAdmin())
        {
            return Unauthorized(new { message = "Yetki yok." });
        }

        var allUsers = _appService.GetUsers();
        var allListings = _appService.GetListings();
        var allOffers = _appService.GetOffers();
        var allRentals = _appService.GetRentals();
        var allMessages = _appService.GetMessages();
        var allRatings = _appService.GetRatings();

        var activeListings = allListings.Where(x => !x.IsRented).ToList();
        var rentedListings = allListings.Where(x => x.IsRented).ToList();
        var pendingSellers = allUsers.Count(x => x.Role == UserRole.Customer && !x.IsSellerApproved);
        var acceptedOffers = allOffers.Count(x => x.Status == OfferStatus.Accepted);
        var rejectedOffers = allOffers.Count(x => x.Status == OfferStatus.Rejected);
        var pendingOffers = allOffers.Count(x => x.Status == OfferStatus.Pending);
        var thisMonth = DateTime.UtcNow;
        var thisMonthOffers = allOffers.Count(x => x.CreatedAt.Year == thisMonth.Year && x.CreatedAt.Month == thisMonth.Month);
        var thisMonthRentals = allRentals.Count(x => x.RentedAt.Year == thisMonth.Year && x.RentedAt.Month == thisMonth.Month);
        var avgListingRating = allRatings.Count > 0 ? Math.Round(allRatings.Average(x => x.ListingScore), 2) : 0;
        var avgSellerRating = allRatings.Count > 0 ? Math.Round(allRatings.Average(x => x.SellerScore), 2) : 0;

        return Ok(new
        {
            totalListings = allListings.Count,
            activeListings = activeListings.Count,
            rentedListings = rentedListings.Count,
            totalUsers = allUsers.Count,
            totalAdmins = allUsers.Count(x => x.Role == UserRole.Admin),
            pendingSellers,
            totalOffers = allOffers.Count,
            pendingOffers,
            acceptedOffers,
            rejectedOffers,
            totalRentals = allRentals.Count,
            totalMessages = allMessages.Count,
            unreadMessages = allMessages.Count(x => !x.IsRead),
            totalRatings = allRatings.Count,
            averageListingRating = avgListingRating,
            averageSellerRating = avgSellerRating,
            thisMonthOffers,
            thisMonthRentals,
            rentalRate = allListings.Count > 0 ? (int)Math.Round((double)rentedListings.Count / allListings.Count * 100) : 0,
            approvalRate = allUsers.Count(x => x.Role != UserRole.Admin) > 0
                ? (int)Math.Round((double)allUsers.Count(x => x.Role == UserRole.Customer && x.IsSellerApproved) / Math.Max(1, allUsers.Count(x => x.Role == UserRole.Customer)) * 100)
                : 100,
            totalRevenuePotential = activeListings.Sum(x => x.MonthlyPrice),
            averageListingPrice = activeListings.Count > 0 ? activeListings.Average(x => x.MonthlyPrice) : 0m,
            adminRecommendedCount = allListings.Count(x => x.IsAdminRecommended),
            dailyRecommendedCount = allListings.Count(x => x.IsDailyRecommended),
            topCities = allListings
                .GroupBy(x => x.Province)
                .OrderByDescending(g => g.Count())
                .Take(5)
                .Select(g => new
                {
                    city = g.Key,
                    count = g.Count(),
                    avgPrice = (int)g.Average(x => (double)x.MonthlyPrice)
                })
                .ToList(),
            topSellers = allListings
                .GroupBy(x => new { x.OwnerUserId, x.OwnerName })
                .Select(g =>
                {
                    var sellerOfferCount = allOffers.Count(o => o.ToOwnerUserId == g.Key.OwnerUserId);
                    var sellerAcceptedCount = allOffers.Count(o => o.ToOwnerUserId == g.Key.OwnerUserId && o.Status == OfferStatus.Accepted);
                    var sellerRented = g.Count(x => x.IsRented);
                    return new
                    {
                        sellerId = g.Key.OwnerUserId,
                        seller = g.Key.OwnerName,
                        listingCount = g.Count(),
                        rentedCount = sellerRented,
                        offerCount = sellerOfferCount,
                        acceptanceRate = sellerOfferCount == 0 ? 0 : (int)Math.Round((double)sellerAcceptedCount / sellerOfferCount * 100)
                    };
                })
                .OrderByDescending(x => x.rentedCount)
                .ThenByDescending(x => x.offerCount)
                .Take(8)
                .ToList(),
            latestListings = allListings.Take(10).Select(ToListingDto).ToList(),
            latestUsers = allUsers.Take(10).Select(ToUserDto).ToList(),
            isSuperAdmin = userIdIsSuperAdmin()
        });
    }

    [HttpGet("users")]
    public IActionResult Users()
    {
        if (!IsAdmin())
        {
            return Unauthorized(new { message = "Yetki yok." });
        }

        return Ok(_appService.GetUsers().Select(ToUserDto).ToList());
    }

    [HttpPost("users")]
    public IActionResult CreateUser([FromBody] UserAdminCreateViewModel model)
    {
        var actorId = CurrentUserId();
        if (!actorId.HasValue || !IsAdmin())
        {
            return Unauthorized(new { message = "Yetki yok." });
        }

        try
        {
            var user = _appService.CreateUserByAdmin(actorId.Value, model);
            return Ok(ToUserDto(user));
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("users/{id:int}")]
    public IActionResult UpdateUser(int id, [FromBody] UserAdminEditViewModel model)
    {
        var actorId = CurrentUserId();
        if (!actorId.HasValue || !IsAdmin())
        {
            return Unauthorized(new { message = "Yetki yok." });
        }

        model.Id = id;
        try
        {
            _appService.UpdateUserByAdmin(actorId.Value, model);
            var user = _appService.GetUser(id);
            return user is null ? NotFound(new { message = "Kullanici bulunamadi." }) : Ok(ToUserDto(user));
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("users/{id:int}/seller-approval")]
    public IActionResult ToggleSellerApproval(int id, [FromBody] SellerApprovalRequest request)
    {
        var actorId = CurrentUserId();
        if (!actorId.HasValue || !IsAdmin())
        {
            return Unauthorized(new { message = "Yetki yok." });
        }

        try
        {
            _appService.SetSellerApproval(actorId.Value, id, request.Approved);
            var user = _appService.GetUser(id);
            return user is null ? NotFound(new { message = "Kullanici bulunamadi." }) : Ok(ToUserDto(user));
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("users/{id:int}/role")]
    public IActionResult ToggleAdminRole(int id, [FromBody] AdminRoleRequest request)
    {
        var actorId = CurrentUserId();
        if (!actorId.HasValue || !IsAdmin())
        {
            return Unauthorized(new { message = "Yetki yok." });
        }

        try
        {
            _appService.SetAdminRole(actorId.Value, id, request.MakeAdmin);
            var user = _appService.GetUser(id);
            return user is null ? NotFound(new { message = "Kullanici bulunamadi." }) : Ok(ToUserDto(user));
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("users/{id:int}")]
    public IActionResult DeleteUser(int id)
    {
        var actorId = CurrentUserId();
        if (!actorId.HasValue || !IsAdmin())
        {
            return Unauthorized(new { message = "Yetki yok." });
        }

        try
        {
            _appService.DeleteUser(actorId.Value, id);
            return Ok(new { message = "Kullanici silindi." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("reports")]
    public IActionResult Reports(
        [FromQuery] string? reportStart = null,
        [FromQuery] string? reportEnd = null,
        [FromQuery] int? reportSellerId = null,
        [FromQuery] string? reportFeature = null,
        [FromQuery] string? reportEvent = null)
    {
        if (!IsAdmin())
        {
            return Unauthorized(new { message = "Yetki yok." });
        }

        return Ok(BuildAdminReports(reportStart, reportEnd, reportSellerId, reportFeature, reportEvent));
    }

    private bool IsAdmin() => CurrentUserId().HasValue && string.Equals(HttpContext.Session.GetString("Role"), UserRole.Admin.ToString(), StringComparison.OrdinalIgnoreCase);

    private bool userIdIsSuperAdmin() => CurrentUserId().HasValue && _appService.IsSuperAdmin(CurrentUserId()!.Value);

    private int? CurrentUserId() => HttpContext.Session.GetInt32("UserId");

    private static object ToUserDto(User user) => new
    {
        user.Id,
        user.FullName,
        user.Email,
        user.PhoneNumber,
        user.Role,
        user.Bio,
        user.ProfileImageUrl,
        user.IsSellerApproved,
        isSuperAdmin = string.Equals(user.Email.Trim(), AppService.SuperAdminEmail, StringComparison.OrdinalIgnoreCase)
    };

    private static object ToListingDto(Listing listing) => new
    {
        listing.Id,
        listing.Title,
        listing.Description,
        listing.Province,
        listing.District,
        listing.City,
        listing.PropertyType,
        listing.ListingPurpose,
        listing.RoomCount,
        listing.GrossSquareMeters,
        listing.NetSquareMeters,
        listing.BuildingAge,
        listing.Floor,
        listing.TotalFloors,
        listing.BathroomCount,
        listing.HeatingType,
        listing.Furnished,
        listing.Balcony,
        listing.Elevator,
        listing.Parking,
        listing.InSite,
        listing.HasPool,
        listing.MonthlyPrice,
        listing.Deposit,
        listing.Dues,
        listing.ImageUrl,
        listing.ImageGalleryJson,
        listing.OwnerUserId,
        listing.OwnerName,
        listing.IsRented,
        listing.RentedAt,
        listing.IsDailyRecommended,
        listing.IsAdminRecommended,
        listing.CreatedAt
    };

    private AdminReportsViewModel BuildAdminReports(
        string? reportStart,
        string? reportEnd,
        int? reportSellerId,
        string? reportFeature,
        string? reportEvent)
    {
        var allListings = _appService.GetListings();
        var allOffers = _appService.GetOffers();
        var allComments = _appService.GetComments();
        var allRatings = _appService.GetRatings();
        var allRentals = _appService.GetRentals();
        var allUsers = _appService.GetUsers();

        var usersById = allUsers.ToDictionary(x => x.Id, x => x.FullName);
        var listingsById = allListings.ToDictionary(x => x.Id, x => x);

        var start = ParseDateTimeLocalInput(reportStart);
        var end = ParseDateTimeLocalInput(reportEnd);
        var feature = string.IsNullOrWhiteSpace(reportFeature) ? "all" : reportFeature.Trim().ToLowerInvariant();
        var eventFilter = string.IsNullOrWhiteSpace(reportEvent) ? "all" : reportEvent.Trim().ToLowerInvariant();

        var sellerOptions = allListings
            .GroupBy(x => new { x.OwnerUserId, x.OwnerName })
            .OrderBy(x => x.Key.OwnerName)
            .Select(x => new AdminReportSellerOptionViewModel
            {
                SellerId = x.Key.OwnerUserId,
                SellerName = x.Key.OwnerName
            })
            .ToList();

        var filteredListings = allListings.AsEnumerable();
        if (reportSellerId.HasValue)
        {
            filteredListings = filteredListings.Where(x => x.OwnerUserId == reportSellerId.Value);
        }

        filteredListings = feature switch
        {
            "balcony" => filteredListings.Where(x => x.Balcony),
            "parking" => filteredListings.Where(x => x.Parking),
            "elevator" => filteredListings.Where(x => x.Elevator),
            "insite" => filteredListings.Where(x => x.InSite),
            "pool" => filteredListings.Where(x => x.HasPool),
            "furnished" => filteredListings.Where(x => x.Furnished),
            "admin_recommended" => filteredListings.Where(x => x.IsAdminRecommended),
            "daily_recommended" => filteredListings.Where(x => x.IsDailyRecommended),
            "rented" => filteredListings.Where(x => x.IsRented),
            _ => filteredListings
        };

        var listingIds = filteredListings.Select(x => x.Id).ToHashSet();

        var filteredOffers = allOffers
            .Where(x => listingIds.Contains(x.ListingId))
            .Where(x => !start.HasValue || x.CreatedAt >= start.Value)
            .Where(x => !end.HasValue || x.CreatedAt <= end.Value)
            .ToList();

        var filteredComments = allComments
            .Where(x => listingIds.Contains(x.ListingId))
            .Where(x => !start.HasValue || x.CreatedAt >= start.Value)
            .Where(x => !end.HasValue || x.CreatedAt <= end.Value)
            .ToList();

        var filteredRatings = allRatings
            .Where(x => listingIds.Contains(x.ListingId))
            .Where(x => !start.HasValue || x.CreatedAt >= start.Value)
            .Where(x => !end.HasValue || x.CreatedAt <= end.Value)
            .ToList();

        var filteredRentals = allRentals
            .Where(x => listingIds.Contains(x.ListingId))
            .Where(x => !start.HasValue || x.RentedAt >= start.Value)
            .Where(x => !end.HasValue || x.RentedAt <= end.Value)
            .ToList();

        var now = DateTime.UtcNow;
        var thisMonthOffers = filteredOffers.Where(x => x.CreatedAt.Year == now.Year && x.CreatedAt.Month == now.Month).ToList();
        var thisMonthComments = filteredComments.Where(x => x.CreatedAt.Year == now.Year && x.CreatedAt.Month == now.Month).ToList();
        var thisMonthRatings = filteredRatings.Where(x => x.CreatedAt.Year == now.Year && x.CreatedAt.Month == now.Month).ToList();

        var offers = filteredOffers
            .OrderByDescending(x => x.CreatedAt)
            .Select(x =>
            {
                var listing = listingsById.TryGetValue(x.ListingId, out var l) ? l : null;
                return new AdminReportOfferItemViewModel
                {
                    OfferId = x.Id,
                    ListingId = x.ListingId,
                    ListingTitle = listing?.Title ?? "İlan",
                    SellerName = listing?.OwnerName ?? "-",
                    CustomerName = usersById.TryGetValue(x.FromUserId, out var customerName) ? customerName : "Kullanici",
                    OfferType = x.Type == OfferType.RentalRequest ? "Kiralama Talebi" : "Fiyat Teklifi",
                    Amount = x.Amount,
                    Status = x.Type == OfferType.RentalRequest && x.Status == OfferStatus.Accepted
                        ? "Kiralandi"
                        : x.Status == OfferStatus.Accepted
                            ? "Kabul"
                            : x.Status == OfferStatus.Rejected ? "Red" : "Beklemede",
                    CreatedAt = x.CreatedAt
                };
            })
            .ToList();

        var comments = filteredComments
            .OrderByDescending(x => x.CreatedAt)
            .Select(x =>
            {
                var listing = listingsById.TryGetValue(x.ListingId, out var l) ? l : null;
                return new AdminReportCommentItemViewModel
                {
                    ListingId = x.ListingId,
                    ListingTitle = listing?.Title ?? "İlan",
                    SellerName = listing?.OwnerName ?? "-",
                    AuthorName = x.AuthorName,
                    Content = x.Content,
                    CreatedAt = x.CreatedAt
                };
            })
            .ToList();

        var ratings = filteredRatings
            .OrderByDescending(x => x.CreatedAt)
            .Select(x =>
            {
                var listing = listingsById.TryGetValue(x.ListingId, out var l) ? l : null;
                return new AdminReportRatingItemViewModel
                {
                    ListingId = x.ListingId,
                    ListingTitle = listing?.Title ?? "İlan",
                    SellerName = listing?.OwnerName ?? "-",
                    RenterName = usersById.TryGetValue(x.RenterUserId, out var renterName) ? renterName : "Kullanici",
                    ListingScore = x.ListingScore,
                    SellerScore = x.SellerScore,
                    Comment = x.Comment,
                    CreatedAt = x.CreatedAt
                };
            })
            .ToList();

        var sales = filteredRentals
            .OrderByDescending(x => x.RentedAt)
            .Select(x =>
            {
                var listing = listingsById.TryGetValue(x.ListingId, out var l) ? l : null;
                return new AdminReportSaleItemViewModel
                {
                    ListingId = x.ListingId,
                    ListingTitle = listing?.Title ?? "İlan",
                    SellerName = listing?.OwnerName ?? "-",
                    BuyerName = usersById.TryGetValue(x.RenterUserId, out var buyerName) ? buyerName : "Kullanici",
                    Amount = listing?.MonthlyPrice ?? 0,
                    SoldAt = x.RentedAt
                };
            })
            .ToList();

        var sellerPerformance = filteredListings
            .GroupBy(x => new { x.OwnerUserId, x.OwnerName })
            .Select(g =>
            {
                var sellerListingIds = g.Select(x => x.Id).ToHashSet();
                var sellerOffers = filteredOffers.Where(o => sellerListingIds.Contains(o.ListingId)).ToList();
                return new AdminReportSellerPerformanceViewModel
                {
                    SellerId = g.Key.OwnerUserId,
                    SellerName = g.Key.OwnerName,
                    ListingCount = g.Count(),
                    OfferCount = sellerOffers.Count,
                    AcceptedOfferCount = sellerOffers.Count(x => x.Status == OfferStatus.Accepted),
                    CommentCount = filteredComments.Count(c => sellerListingIds.Contains(c.ListingId)),
                    RatingCount = filteredRatings.Count(r => sellerListingIds.Contains(r.ListingId)),
                    SalesCount = filteredRentals.Count(r => sellerListingIds.Contains(r.ListingId))
                };
            })
            .OrderByDescending(x => x.SalesCount)
            .ThenByDescending(x => x.OfferCount)
            .ToList();

        if (eventFilter == "offers")
        {
            comments = new List<AdminReportCommentItemViewModel>();
            ratings = new List<AdminReportRatingItemViewModel>();
            sales = new List<AdminReportSaleItemViewModel>();
        }
        else if (eventFilter == "comments")
        {
            offers = new List<AdminReportOfferItemViewModel>();
            ratings = new List<AdminReportRatingItemViewModel>();
            sales = new List<AdminReportSaleItemViewModel>();
        }
        else if (eventFilter == "ratings")
        {
            offers = new List<AdminReportOfferItemViewModel>();
            comments = new List<AdminReportCommentItemViewModel>();
            sales = new List<AdminReportSaleItemViewModel>();
        }
        else if (eventFilter == "sales")
        {
            offers = new List<AdminReportOfferItemViewModel>();
            comments = new List<AdminReportCommentItemViewModel>();
            ratings = new List<AdminReportRatingItemViewModel>();
        }

        return new AdminReportsViewModel
        {
            StartAt = ToDateTimeLocalValue(start, reportStart),
            EndAt = ToDateTimeLocalValue(end, reportEnd),
            SellerUserId = reportSellerId,
            FeatureFilter = feature,
            EventFilter = eventFilter,
            TotalOffers = filteredOffers.Count,
            TotalComments = filteredComments.Count,
            TotalRatings = filteredRatings.Count,
            TotalSales = filteredRentals.Count,
            UniqueOfferUsers = filteredOffers.Select(x => x.FromUserId).Distinct().Count(),
            UniqueCommentUsers = filteredComments.Select(x => (x.AuthorName ?? string.Empty).Trim().ToLowerInvariant()).Where(x => x.Length > 0).Distinct().Count(),
            UniqueRatingUsers = filteredRatings.Select(x => x.RenterUserId).Distinct().Count(),
            UniqueBuyers = filteredRentals.Select(x => x.RenterUserId).Distinct().Count(),
            ThisMonthOfferCount = thisMonthOffers.Count,
            ThisMonthCommentCount = thisMonthComments.Count,
            ThisMonthRatingCount = thisMonthRatings.Count,
            SellerOptions = sellerOptions,
            Offers = offers,
            Comments = comments,
            Ratings = ratings,
            Sales = sales,
            SellerPerformance = sellerPerformance
        };
    }

    private static DateTime? ParseDateTimeLocalInput(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        if (DateTime.TryParse(value, out var parsed))
        {
            return DateTime.SpecifyKind(parsed, DateTimeKind.Local).ToUniversalTime();
        }

        return null;
    }

    private static string ToDateTimeLocalValue(DateTime? utcValue, string? rawInput)
    {
        if (utcValue.HasValue)
        {
            return utcValue.Value.ToLocalTime().ToString("yyyy-MM-ddTHH:mm");
        }

        return string.IsNullOrWhiteSpace(rawInput) ? string.Empty : rawInput.Trim();
    }
}

public class SellerApprovalRequest
{
    public bool Approved { get; set; }
}

public class AdminRoleRequest
{
    public bool MakeAdmin { get; set; }
}
