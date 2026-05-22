using Degerliyuvam.Services;
using Degerliyuvam.Models;
using Degerliyuvam.ViewModels;
using Microsoft.AspNetCore.Mvc;
using PdfSharpCore.Drawing;
using PdfSharpCore.Pdf;
using System.Text;

namespace Degerliyuvam.Controllers;

public class AdminController : Controller
{
    private readonly AppService _appService;

    public AdminController(AppService appService)
    {
        _appService = appService;
    }

    public IActionResult Dashboard(
        string? tab = "overview",
        string? userSearch = null,
        string? listingSearch = null,
        string? dateFrom = null,
        string? dateTo = null,
        string? listingStatus = null,
        string? globalSearch = null,
        string? sort = null,
        string? reportStart = null,
        string? reportEnd = null,
        int? reportSellerId = null,
        string? reportFeature = null,
        string? reportEvent = null)
    {
        if (!AuthSession.IsAdmin(this)) return RedirectToAction("Login", "Account");
        var currentUserId = AuthSession.UserId(this);
        if (!currentUserId.HasValue) return RedirectToAction("Login", "Account");
        var isSuperAdmin = _appService.IsSuperAdmin(currentUserId.Value);

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
        var rentalRequestCount = allOffers.Count(x => x.Type == OfferType.RentalRequest);
        var priceOfferCount = allOffers.Count(x => x.Type == OfferType.PriceOffer);
        var avgListingRating = allRatings.Count > 0 ? Math.Round(allRatings.Average(x => x.ListingScore), 2) : 0;
        var avgSellerRating = allRatings.Count > 0 ? Math.Round(allRatings.Average(x => x.SellerScore), 2) : 0;
        var thisMonth = DateTime.UtcNow;
        var thisMonthOffers = allOffers.Count(x => x.CreatedAt.Year == thisMonth.Year && x.CreatedAt.Month == thisMonth.Month);
        var thisMonthRentals = allRentals.Count(x => x.RentedAt.Year == thisMonth.Year && x.RentedAt.Month == thisMonth.Month);

        ViewBag.TotalListings = allListings.Count;
        ViewBag.IsSuperAdmin = isSuperAdmin;
        ViewBag.SuperAdminEmail = AppService.SuperAdminEmail;
        ViewBag.TotalUsers = allUsers.Count;
        ViewBag.TotalAdmins = allUsers.Count(x => x.Role == UserRole.Admin);
        ViewBag.PendingSellers = pendingSellers;
        ViewBag.ActiveListings = activeListings.Count;
        ViewBag.RentedListings = rentedListings.Count;
        ViewBag.TotalRevenuePotential = activeListings.Sum(x => x.MonthlyPrice);
        ViewBag.AverageListingPrice = activeListings.Count > 0
            ? activeListings.Average(x => x.MonthlyPrice)
            : 0m;
        ViewBag.AdminRecommendedCount = allListings.Count(x => x.IsAdminRecommended);
        ViewBag.DailyRecommendedCount = allListings.Count(x => x.IsDailyRecommended);
        ViewBag.NewListingsThisMonth = allListings.Count(x => x.CreatedAt.Month == DateTime.UtcNow.Month && x.CreatedAt.Year == DateTime.UtcNow.Year);
        ViewBag.NewUsersThisMonth = 0;
        ViewBag.TotalOffers = allOffers.Count;
        ViewBag.PendingOffers = pendingOffers;
        ViewBag.AcceptedOffers = acceptedOffers;
        ViewBag.RejectedOffers = rejectedOffers;
        ViewBag.RentalRequestCount = rentalRequestCount;
        ViewBag.PriceOfferCount = priceOfferCount;
        ViewBag.TotalRentals = allRentals.Count;
        ViewBag.TotalMessages = allMessages.Count;
        ViewBag.UnreadMessages = allMessages.Count(x => !x.IsRead);
        ViewBag.TotalRatings = allRatings.Count;
        ViewBag.AverageListingRating = avgListingRating;
        ViewBag.AverageSellerRating = avgSellerRating;
        ViewBag.ThisMonthOffers = thisMonthOffers;
        ViewBag.ThisMonthRentals = thisMonthRentals;
        ViewBag.RentalRate = allListings.Count > 0
            ? (int)Math.Round((double)rentedListings.Count / allListings.Count * 100)
            : 0;
        ViewBag.ApprovalRate = allUsers.Count(x => x.Role != UserRole.Admin) > 0
            ? (int)Math.Round((double)allUsers.Count(x => x.Role == UserRole.Customer && x.IsSellerApproved) / Math.Max(1, allUsers.Count(x => x.Role == UserRole.Customer)) * 100)
            : 100;

        var filteredUsers = allUsers.AsEnumerable();
        if (!string.IsNullOrWhiteSpace(userSearch))
        {
            var q = userSearch.Trim().ToLowerInvariant();
            filteredUsers = filteredUsers.Where(u =>
                u.FullName.ToLowerInvariant().Contains(q) ||
                u.Email.ToLowerInvariant().Contains(q));
        }
        ViewBag.Users = filteredUsers.ToList();
        ViewBag.UserSearch = userSearch;

        var filteredListings = allListings.AsEnumerable();

        if (!string.IsNullOrWhiteSpace(listingSearch))
        {
            var q = listingSearch.Trim().ToLowerInvariant();
            filteredListings = filteredListings.Where(l =>
                l.Title.ToLowerInvariant().Contains(q) ||
                l.Province.ToLowerInvariant().Contains(q) ||
                l.OwnerName.ToLowerInvariant().Contains(q));
        }

        if (DateTime.TryParse(dateFrom, out var dfrom))
            filteredListings = filteredListings.Where(l => l.CreatedAt.Date >= dfrom.Date);

        if (DateTime.TryParse(dateTo, out var dto))
            filteredListings = filteredListings.Where(l => l.CreatedAt.Date <= dto.Date);

        if (listingStatus == "active")
            filteredListings = filteredListings.Where(l => !l.IsRented);
        else if (listingStatus == "rented")
            filteredListings = filteredListings.Where(l => l.IsRented);

        filteredListings = sort switch
        {
            "oldest" => filteredListings.OrderBy(l => l.CreatedAt),
            "price_desc" => filteredListings.OrderByDescending(l => l.MonthlyPrice),
            "price_asc" => filteredListings.OrderBy(l => l.MonthlyPrice),
            _ => filteredListings.OrderByDescending(l => l.CreatedAt)
        };

        ViewBag.ListingSearch = listingSearch;
        ViewBag.DateFrom = dateFrom;
        ViewBag.DateTo = dateTo;
        ViewBag.ListingStatus = listingStatus;
        ViewBag.Sort = sort;

        List<User> searchUsers = new();
        List<Listing> searchListings = new();
        if (!string.IsNullOrWhiteSpace(globalSearch))
        {
            var q = globalSearch.Trim().ToLowerInvariant();
            searchUsers = allUsers.Where(u =>
                u.FullName.ToLowerInvariant().Contains(q) ||
                u.Email.ToLowerInvariant().Contains(q)).ToList();
            searchListings = allListings.Where(l =>
                l.Title.ToLowerInvariant().Contains(q) ||
                l.Province.ToLowerInvariant().Contains(q) ||
                l.OwnerName.ToLowerInvariant().Contains(q)).ToList();
        }
        ViewBag.GlobalSearch = globalSearch;
        ViewBag.SearchUsers = searchUsers;
        ViewBag.SearchListings = searchListings;

        ViewBag.ActiveTab = tab ?? "overview";
        ViewBag.TopCities = allListings
            .GroupBy(x => x.Province)
            .OrderByDescending(g => g.Count())
            .Take(5)
            .Select(g => new { City = g.Key, Count = g.Count(), AvgPrice = (int)g.Average(x => (double)x.MonthlyPrice) })
            .ToList<dynamic>();
        ViewBag.TopSellers = allListings
            .GroupBy(x => new { x.OwnerUserId, x.OwnerName })
            .Select(g =>
            {
                var sellerOfferCount = allOffers.Count(o => o.ToOwnerUserId == g.Key.OwnerUserId);
                var sellerAcceptedCount = allOffers.Count(o => o.ToOwnerUserId == g.Key.OwnerUserId && o.Status == OfferStatus.Accepted);
                var sellerRented = g.Count(x => x.IsRented);
                return new
                {
                    SellerId = g.Key.OwnerUserId,
                    Seller = g.Key.OwnerName,
                    ListingCount = g.Count(),
                    RentedCount = sellerRented,
                    OfferCount = sellerOfferCount,
                    AcceptanceRate = sellerOfferCount == 0 ? 0 : (int)Math.Round((double)sellerAcceptedCount / sellerOfferCount * 100)
                };
            })
            .OrderByDescending(x => x.RentedCount)
            .ThenByDescending(x => x.OfferCount)
            .Take(8)
            .ToList<dynamic>();
        ViewBag.Report = BuildAdminReports(reportStart, reportEnd, reportSellerId, reportFeature, reportEvent);

        return View(filteredListings.ToList());
    }

    [HttpGet]
    public IActionResult ExportReportPdf(
        string? listingSearch = null,
        string? dateFrom = null,
        string? dateTo = null,
        string? listingStatus = null,
        string? sort = null,
        string? reportStart = null,
        string? reportEnd = null,
        int? reportSellerId = null,
        string? reportFeature = null,
        string? reportEvent = null)
    {
        if (!AuthSession.IsAdmin(this)) return RedirectToAction("Login", "Account");

        var allUsers = _appService.GetUsers();
        var allListings = _appService.GetListings();
        var allOffers = _appService.GetOffers();
        var allRentals = _appService.GetRentals();
        var allMessages = _appService.GetMessages();
        var allRatings = _appService.GetRatings();
        var report = BuildAdminReports(reportStart, reportEnd, reportSellerId, reportFeature, reportEvent);

        var filteredListings = allListings.AsEnumerable();
        if (!string.IsNullOrWhiteSpace(listingSearch))
        {
            var q = listingSearch.Trim().ToLowerInvariant();
            filteredListings = filteredListings.Where(l =>
                l.Title.ToLowerInvariant().Contains(q) ||
                l.Province.ToLowerInvariant().Contains(q) ||
                l.OwnerName.ToLowerInvariant().Contains(q));
        }

        if (DateTime.TryParse(dateFrom, out var dfrom))
            filteredListings = filteredListings.Where(l => l.CreatedAt.Date >= dfrom.Date);
        if (DateTime.TryParse(dateTo, out var dto))
            filteredListings = filteredListings.Where(l => l.CreatedAt.Date <= dto.Date);

        if (listingStatus == "active")
            filteredListings = filteredListings.Where(l => !l.IsRented);
        else if (listingStatus == "rented")
            filteredListings = filteredListings.Where(l => l.IsRented);

        filteredListings = sort switch
        {
            "oldest" => filteredListings.OrderBy(l => l.CreatedAt),
            "price_desc" => filteredListings.OrderByDescending(l => l.MonthlyPrice),
            "price_asc" => filteredListings.OrderBy(l => l.MonthlyPrice),
            _ => filteredListings.OrderByDescending(l => l.CreatedAt)
        };

        var filteredList = filteredListings.ToList();

        using var document = new PdfDocument();
        document.Info.Title = "Degerliyuvam Admin Raporu";

        var page = document.AddPage();
        page.Size = PdfSharpCore.PageSize.A4;
        var gfx = XGraphics.FromPdfPage(page);

        var titleFont = new XFont("Arial", 16, XFontStyle.Bold);
        var sectionFont = new XFont("Arial", 11, XFontStyle.Bold);
        var bodyFont = new XFont("Arial", 9, XFontStyle.Regular);

        double y = 32;
        const double left = 36;
        const double right = 560;

        void DrawLine(string text, XFont font, bool addGap = false)
        {
            if (y > 800)
            {
                page = document.AddPage();
                page.Size = PdfSharpCore.PageSize.A4;
                gfx = XGraphics.FromPdfPage(page);
                y = 32;
            }

            gfx.DrawString(text, font, XBrushes.Black, new XRect(left, y, right - left, 20), XStringFormats.TopLeft);
            y += addGap ? 22 : 16;
        }

        var nowText = DateTime.Now.ToString("dd.MM.yyyy HH:mm");
        var avgListingRating = allRatings.Count > 0 ? Math.Round(allRatings.Average(x => x.ListingScore), 2) : 0;
        var avgSellerRating = allRatings.Count > 0 ? Math.Round(allRatings.Average(x => x.SellerScore), 2) : 0;
        var acceptedOffers = allOffers.Count(x => x.Status == OfferStatus.Accepted);
        var pendingOffers = allOffers.Count(x => x.Status == OfferStatus.Pending);
        var rejectedOffers = allOffers.Count(x => x.Status == OfferStatus.Rejected);

        DrawLine("Degerliyuvam - Admin Raporu", titleFont, true);
        DrawLine($"Rapor Tarihi: {nowText}", bodyFont);
        DrawLine($"Filtreli Ilan Sayisi: {filteredList.Count}", bodyFont, true);

        DrawLine("RAPOR FILTRELERI", sectionFont);
        DrawLine($"Baslangic: {(string.IsNullOrWhiteSpace(report.StartAt) ? "-" : report.StartAt)}", bodyFont);
        DrawLine($"Bitis: {(string.IsNullOrWhiteSpace(report.EndAt) ? "-" : report.EndAt)}", bodyFont);
        DrawLine($"Secili Satici: {(report.SellerUserId.HasValue ? report.SellerOptions.FirstOrDefault(x => x.SellerId == report.SellerUserId.Value)?.SellerName ?? "-" : "Tum Saticilar")}", bodyFont);
        DrawLine($"Ozellik Filtresi: {report.FeatureFilter}", bodyFont);
        DrawLine($"Liste Turu: {report.EventFilter}", bodyFont, true);

        DrawLine("GENEL METRIKLER", sectionFont);
        DrawLine($"Toplam Kullanici: {allUsers.Count}", bodyFont);
        DrawLine($"Toplam Ilan: {allListings.Count}", bodyFont);
        DrawLine($"Aktif Ilan: {allListings.Count(x => !x.IsRented)}", bodyFont);
        DrawLine($"Kiralanan Ilan: {allListings.Count(x => x.IsRented)}", bodyFont);
        DrawLine($"Toplam Teklif: {report.TotalOffers}", bodyFont);
        DrawLine($"Teklif Durumu - Bekleyen: {pendingOffers}, Kabul: {acceptedOffers}, Red: {rejectedOffers}", bodyFont);
        DrawLine($"Toplam Kiralama Kaydi: {report.TotalSales}", bodyFont);
        DrawLine($"Toplam Mesaj: {allMessages.Count}", bodyFont);
        DrawLine($"Okunmamis Mesaj: {allMessages.Count(x => !x.IsRead)}", bodyFont);
        DrawLine($"Puanlama - Ortalama Ilan: {avgListingRating:0.00}, Ortalama Satici: {avgSellerRating:0.00}", bodyFont);
        DrawLine($"Yorum Sayisi: {report.TotalComments} (Tekil yorumcu: {report.UniqueCommentUsers})", bodyFont);
        DrawLine($"Degerlendirme Sayisi: {report.TotalRatings} (Tekil degerlendiren: {report.UniqueRatingUsers})", bodyFont);
        DrawLine($"Bu Ay Teklif/Yorum/Degerlendirme: {report.ThisMonthOfferCount}/{report.ThisMonthCommentCount}/{report.ThisMonthRatingCount}", bodyFont, true);

        DrawLine("SEHIR BAZLI OZET", sectionFont);
        foreach (var city in allListings
            .GroupBy(x => x.Province)
            .OrderByDescending(x => x.Count())
            .Take(8))
        {
            var avg = city.Average(x => x.MonthlyPrice);
            DrawLine($"{city.Key}: {city.Count()} ilan, Ortalama Fiyat: {avg:N0} TL", bodyFont);
        }
        y += 4;

        DrawLine("EN COK TEKLIF ALAN ILANLAR", sectionFont);
        var topListings = allListings
            .Select(l => new
            {
                l.Title,
                l.Province,
                l.District,
                OfferCount = allOffers.Count(o => o.ListingId == l.Id),
                l.MonthlyPrice
            })
            .OrderByDescending(x => x.OfferCount)
            .ThenByDescending(x => x.MonthlyPrice)
            .Take(12)
            .ToList();
        foreach (var listing in topListings)
        {
            DrawLine($"{listing.Title} ({listing.Province}/{listing.District}) - {listing.OfferCount} teklif - {listing.MonthlyPrice:N0} TL", bodyFont);
        }
        y += 4;

        DrawLine("SATIS LISTESI (KIM NE ALDI)", sectionFont);
        foreach (var sale in report.Sales.Take(20))
        {
            DrawLine($"{sale.BuyerName} -> {sale.ListingTitle} / {sale.SellerName} / {sale.Amount:N0} TL / {sale.SoldAt.ToLocalTime():dd.MM.yyyy HH:mm}", bodyFont);
        }
        if (!report.Sales.Any())
        {
            DrawLine("Secilen filtrede satis kaydi yok.", bodyFont);
        }
        y += 4;

        DrawLine("YORUM LISTESI", sectionFont);
        foreach (var c in report.Comments.Take(20))
        {
            var shortText = c.Content.Length > 80 ? c.Content[..80] + "..." : c.Content;
            DrawLine($"{c.AuthorName} / {c.ListingTitle} / {c.CreatedAt.ToLocalTime():dd.MM.yyyy HH:mm} / {shortText}", bodyFont);
        }
        if (!report.Comments.Any())
        {
            DrawLine("Secilen filtrede yorum yok.", bodyFont);
        }
        y += 4;

        DrawLine("TEKLIF LISTESI", sectionFont);
        foreach (var o in report.Offers.Take(20))
        {
            DrawLine($"#{o.OfferId} {o.CustomerName} -> {o.ListingTitle} / {o.Amount:N0} TL / {o.Status} / {o.CreatedAt.ToLocalTime():dd.MM.yyyy HH:mm}", bodyFont);
        }
        if (!report.Offers.Any())
        {
            DrawLine("Secilen filtrede teklif yok.", bodyFont);
        }

        using var stream = new MemoryStream();
        document.Save(stream, false);
        var bytes = stream.ToArray();
        var fileName = $"admin-rapor-{DateTime.Now:yyyyMMdd-HHmm}.pdf";
        return File(bytes, "application/pdf", fileName);
    }

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

    [HttpPost]
    public IActionResult DeleteComment(int commentId, int listingId)
    {
        if (!AuthSession.IsAdmin(this)) return RedirectToAction("Login", "Account");
        _appService.DeleteComment(commentId);
        return RedirectToAction("Details", "Listings", new { id = listingId });
    }

    [HttpGet]
    public IActionResult EditUser(int id)
    {
        if (!AuthSession.IsAdmin(this)) return RedirectToAction("Login", "Account");
        var currentUserId = AuthSession.UserId(this);
        if (!currentUserId.HasValue) return RedirectToAction("Login", "Account");

        var user = _appService.GetUser(id);
        if (user is null) return NotFound();
        var isTargetSuperAdmin = string.Equals(user.Email.Trim(), AppService.SuperAdminEmail, StringComparison.OrdinalIgnoreCase);
        if (isTargetSuperAdmin && !_appService.IsSuperAdmin(currentUserId.Value))
        {
            TempData["Error"] = "Super admin hesabi yalnizca super admin tarafindan duzenlenebilir.";
            return RedirectToAction(nameof(Dashboard), new { tab = "users" });
        }

        ViewBag.IsSuperAdmin = _appService.IsSuperAdmin(currentUserId.Value);
        ViewBag.SuperAdminEmail = AppService.SuperAdminEmail;
        return View(new UserAdminEditViewModel
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Role = user.Role,
            IsSellerApproved = user.IsSellerApproved,
            Bio = user.Bio,
            ProfileImageUrl = user.ProfileImageUrl
        });
    }

    [HttpPost]
    public IActionResult EditUser(UserAdminEditViewModel model)
    {
        if (!AuthSession.IsAdmin(this)) return RedirectToAction("Login", "Account");
        var currentUserId = AuthSession.UserId(this);
        if (!currentUserId.HasValue) return RedirectToAction("Login", "Account");

        if (!ModelState.IsValid)
        {
            ViewBag.IsSuperAdmin = _appService.IsSuperAdmin(currentUserId.Value);
            ViewBag.SuperAdminEmail = AppService.SuperAdminEmail;
            return View(model);
        }

        try
        {
            _appService.UpdateUserByAdmin(currentUserId.Value, model);
            TempData["Success"] = "Kullanici bilgileri guncellendi.";
            return RedirectToAction(nameof(Dashboard), new { tab = "users" });
        }
        catch (Exception ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            ViewBag.IsSuperAdmin = _appService.IsSuperAdmin(currentUserId.Value);
            ViewBag.SuperAdminEmail = AppService.SuperAdminEmail;
            return View(model);
        }
    }

    [HttpPost]
    public IActionResult ToggleSellerApproval(int id)
    {
        if (!AuthSession.IsAdmin(this)) return RedirectToAction("Login", "Account");
        var currentUserId = AuthSession.UserId(this);
        if (!currentUserId.HasValue) return RedirectToAction("Login", "Account");
        var user = _appService.GetUser(id);
        if (user is null) return RedirectToAction(nameof(Dashboard));

        try
        {
            _appService.SetSellerApproval(currentUserId.Value, id, !user.IsSellerApproved);
            TempData["Success"] = user.IsSellerApproved ? "Satıcı onayi kaldirildi." : "Satıcı onayi verildi.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }
        return RedirectToAction(nameof(Dashboard), new { tab = "users" });
    }

    [HttpPost]
    public IActionResult ToggleAdminRole(int id)
    {
        if (!AuthSession.IsAdmin(this)) return RedirectToAction("Login", "Account");
        var currentUserId = AuthSession.UserId(this);
        if (!currentUserId.HasValue) return RedirectToAction("Login", "Account");
        var user = _appService.GetUser(id);
        if (user is null) return RedirectToAction(nameof(Dashboard));

        try
        {
            var makeAdmin = user.Role != UserRole.Admin;
            _appService.SetAdminRole(currentUserId.Value, id, makeAdmin);
            TempData["Success"] = makeAdmin ? "Kullanici admin yapildi." : "Kullanicinin admin rolu kaldirildi.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction(nameof(Dashboard), new { tab = "users" });
    }

    [HttpPost]
    public IActionResult DeleteUser(int id)
    {
        if (!AuthSession.IsAdmin(this)) return RedirectToAction("Login", "Account");
        var currentUserId = AuthSession.UserId(this);
        if (!currentUserId.HasValue) return RedirectToAction("Login", "Account");

        try
        {
            _appService.DeleteUser(currentUserId.Value, id);
            TempData["Success"] = "Kullanici silindi.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }

        if (currentUserId.HasValue && currentUserId.Value == id)
        {
            AuthSession.SignOut(this);
            return RedirectToAction("Index", "Home");
        }

        return RedirectToAction(nameof(Dashboard), new { tab = "users" });
    }

    [HttpGet]
    public IActionResult CreateUser()
    {
        if (!AuthSession.IsAdmin(this)) return RedirectToAction("Login", "Account");
        var currentUserId = AuthSession.UserId(this);
        if (!currentUserId.HasValue) return RedirectToAction("Login", "Account");

        ViewBag.IsSuperAdmin = _appService.IsSuperAdmin(currentUserId.Value);
        ViewBag.SuperAdminEmail = AppService.SuperAdminEmail;
        return View(new UserAdminCreateViewModel
        {
            IsSellerApproved = true,
            Role = UserRole.Customer
        });
    }

    [HttpPost]
    public IActionResult CreateUser(UserAdminCreateViewModel model)
    {
        if (!AuthSession.IsAdmin(this)) return RedirectToAction("Login", "Account");
        var currentUserId = AuthSession.UserId(this);
        if (!currentUserId.HasValue) return RedirectToAction("Login", "Account");

        if (!ModelState.IsValid)
        {
            ViewBag.IsSuperAdmin = _appService.IsSuperAdmin(currentUserId.Value);
            ViewBag.SuperAdminEmail = AppService.SuperAdminEmail;
            return View(model);
        }

        try
        {
            _appService.CreateUserByAdmin(currentUserId.Value, model);
            TempData["Success"] = "Yeni kullanici olusturuldu.";
            return RedirectToAction(nameof(Dashboard), new { tab = "users" });
        }
        catch (Exception ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            ViewBag.IsSuperAdmin = _appService.IsSuperAdmin(currentUserId.Value);
            ViewBag.SuperAdminEmail = AppService.SuperAdminEmail;
            return View(model);
        }
    }

    [HttpPost]
    public IActionResult BulkDeleteListings(List<int> listingIds)
    {
        if (!AuthSession.IsAdmin(this)) return RedirectToAction("Login", "Account");
        if (listingIds is null || listingIds.Count == 0)
        {
            TempData["Error"] = "Silmek icin en az bir ilan secin.";
            return RedirectToAction(nameof(Dashboard), new { tab = "listings" });
        }

        var uniqueIds = listingIds.Distinct().ToList();
        foreach (var id in uniqueIds)
        {
            _appService.DeleteListing(id);
        }

        TempData["Success"] = $"{uniqueIds.Count} ilan toplu olarak silindi.";
        return RedirectToAction(nameof(Dashboard), new { tab = "listings" });
    }
}
