namespace Degerliyuvam.ViewModels;

public class AdminReportsViewModel
{
    public string StartAt { get; set; } = string.Empty;
    public string EndAt { get; set; } = string.Empty;
    public int? SellerUserId { get; set; }
    public string FeatureFilter { get; set; } = "all";
    public string EventFilter { get; set; } = "all";

    public int TotalOffers { get; set; }
    public int TotalComments { get; set; }
    public int TotalRatings { get; set; }
    public int TotalSales { get; set; }

    public int UniqueOfferUsers { get; set; }
    public int UniqueCommentUsers { get; set; }
    public int UniqueRatingUsers { get; set; }
    public int UniqueBuyers { get; set; }

    public int ThisMonthOfferCount { get; set; }
    public int ThisMonthCommentCount { get; set; }
    public int ThisMonthRatingCount { get; set; }

    public List<AdminReportSellerOptionViewModel> SellerOptions { get; set; } = new List<AdminReportSellerOptionViewModel>();
    public List<AdminReportOfferItemViewModel> Offers { get; set; } = new List<AdminReportOfferItemViewModel>();
    public List<AdminReportCommentItemViewModel> Comments { get; set; } = new List<AdminReportCommentItemViewModel>();
    public List<AdminReportRatingItemViewModel> Ratings { get; set; } = new List<AdminReportRatingItemViewModel>();
    public List<AdminReportSaleItemViewModel> Sales { get; set; } = new List<AdminReportSaleItemViewModel>();
    public List<AdminReportSellerPerformanceViewModel> SellerPerformance { get; set; } = new List<AdminReportSellerPerformanceViewModel>();
}

public class AdminReportSellerOptionViewModel
{
    public int SellerId { get; set; }
    public string SellerName { get; set; } = string.Empty;
}

public class AdminReportOfferItemViewModel
{
    public int OfferId { get; set; }
    public int ListingId { get; set; }
    public string ListingTitle { get; set; } = string.Empty;
    public string SellerName { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string OfferType { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class AdminReportCommentItemViewModel
{
    public int ListingId { get; set; }
    public string ListingTitle { get; set; } = string.Empty;
    public string SellerName { get; set; } = string.Empty;
    public string AuthorName { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class AdminReportRatingItemViewModel
{
    public int ListingId { get; set; }
    public string ListingTitle { get; set; } = string.Empty;
    public string SellerName { get; set; } = string.Empty;
    public string RenterName { get; set; } = string.Empty;
    public int ListingScore { get; set; }
    public int SellerScore { get; set; }
    public string Comment { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class AdminReportSaleItemViewModel
{
    public int ListingId { get; set; }
    public string ListingTitle { get; set; } = string.Empty;
    public string SellerName { get; set; } = string.Empty;
    public string BuyerName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public DateTime SoldAt { get; set; }
}

public class AdminReportSellerPerformanceViewModel
{
    public int SellerId { get; set; }
    public string SellerName { get; set; } = string.Empty;
    public int ListingCount { get; set; }
    public int OfferCount { get; set; }
    public int AcceptedOfferCount { get; set; }
    public int CommentCount { get; set; }
    public int RatingCount { get; set; }
    public int SalesCount { get; set; }
}
