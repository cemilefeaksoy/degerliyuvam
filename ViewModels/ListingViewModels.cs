using System.ComponentModel.DataAnnotations;
using Degerliyuvam.Models;
using Microsoft.AspNetCore.Http;

namespace Degerliyuvam.ViewModels;

public class ListingDetailsViewModel
{
    public Listing Listing { get; set; } = new();
    public List<string> GalleryImages { get; set; } = new List<string>();
    public User? OwnerUser { get; set; }
    public List<Comment> Comments { get; set; } = new List<Comment>();
    public List<OfferDisplayViewModel> Offers { get; set; } = new List<OfferDisplayViewModel>();
    public List<RatingDisplayViewModel> Ratings { get; set; } = new List<RatingDisplayViewModel>();

    public bool CanEdit { get; set; }
    public bool IsAdmin { get; set; }
    public bool IsLoggedIn { get; set; }
    public bool CanRent { get; set; }
    public bool CanOffer { get; set; }
    public bool CanComment { get; set; }
    public bool CanRate { get; set; }

    public double ListingRatingAverage { get; set; }
    public int ListingRatingCount { get; set; }
    public double SellerRatingAverage { get; set; }
    public int SellerRatingCount { get; set; }
    public int? MyListingScore { get; set; }
    public int? MySellerScore { get; set; }
    public string MyRatingComment { get; set; } = string.Empty;
}

public class ListingEditViewModel
{
    public int Id { get; set; }
    public int? OwnerUserId { get; set; }

    [Required, StringLength(120)]
    public string Title { get; set; } = string.Empty;

    [Required, StringLength(1000)]
    public string Description { get; set; } = string.Empty;

    [Required]
    public string Province { get; set; } = string.Empty;

    [Required]
    public string District { get; set; } = string.Empty;

    [Required]
    public string PropertyType { get; set; } = "Daire";

    [Required]
    public string ListingPurpose { get; set; } = "Kiralik";

    [Required]
    public string RoomCount { get; set; } = "2+1";

    [Range(10, 5000)]
    public int GrossSquareMeters { get; set; }

    [Range(10, 5000)]
    public int NetSquareMeters { get; set; }

    [Range(0, 80)]
    public int BuildingAge { get; set; }

    [Range(0, 100)]
    public int Floor { get; set; }

    [Range(1, 150)]
    public int TotalFloors { get; set; }

    [Range(1, 20)]
    public int BathroomCount { get; set; }

    [Required]
    public string HeatingType { get; set; } = "Kombi Dogalgaz";

    public bool Furnished { get; set; }
    public bool Balcony { get; set; }
    public bool Elevator { get; set; }
    public bool Parking { get; set; }
    public bool InSite { get; set; }
    public bool HasPool { get; set; }

    [Range(1000, 1000000)]
    public decimal MonthlyPrice { get; set; }

    [Range(0, 1000000)]
    public decimal Deposit { get; set; }

    [Range(0, 100000)]
    public decimal Dues { get; set; }

    public string ImageUrl { get; set; } = string.Empty;
    public string CoverImageUrl { get; set; } = string.Empty;
    public IFormFile? ImageFile { get; set; }
    public List<IFormFile> ImageFiles { get; set; } = new List<IFormFile>();
    public string AdditionalImageUrls { get; set; } = string.Empty;
    public string ExistingImagesCsv { get; set; } = string.Empty;
    public bool ResetExistingImages { get; set; }

    public bool IsAdminRecommended { get; set; }
    public bool TermsAccepted { get; set; }
}

public class OfferCreateViewModel
{
    public int ListingId { get; set; }

    [Range(1000, 1000000)]
    public decimal Amount { get; set; }

    [StringLength(600)]
    public string Note { get; set; } = string.Empty;
}

public class RatingCreateViewModel
{
    public int ListingId { get; set; }

    [Range(1, 5)]
    public int ListingScore { get; set; }

    [Range(1, 5)]
    public int SellerScore { get; set; }

    [StringLength(400)]
    public string Comment { get; set; } = string.Empty;
}

public class OfferDisplayViewModel
{
    public int OfferId { get; set; }
    public int ListingId { get; set; }
    public string ListingTitle { get; set; } = string.Empty;
    public string FromUserName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Note { get; set; } = string.Empty;
    public OfferType Type { get; set; }
    public OfferStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class RatingDisplayViewModel
{
    public string RenterName { get; set; } = string.Empty;
    public int ListingScore { get; set; }
    public int SellerScore { get; set; }
    public string Comment { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class PaymentViewModel
{
    public int ListingId { get; set; }
    public string ListingTitle { get; set; } = string.Empty;

    [Required, StringLength(16, MinimumLength = 12)]
    public string CardNumber { get; set; } = string.Empty;

    [Required, StringLength(5)]
    public string Expiry { get; set; } = string.Empty;

    [Required, StringLength(4, MinimumLength = 3)]
    public string Cvv { get; set; } = string.Empty;
}
