using System.ComponentModel.DataAnnotations;

namespace Degerliyuvam.Models;

public class Listing
{
    public int Id { get; set; }

    [Required, StringLength(120)]
    public string Title { get; set; } = string.Empty;

    [Required, StringLength(1000)]
    public string Description { get; set; } = string.Empty;

    [Required, StringLength(80)]
    public string Province { get; set; } = string.Empty;

    [Required, StringLength(80)]
    public string District { get; set; } = string.Empty;

    // Legacy display field used in list cards.
    public string City { get; set; } = string.Empty;

    [Required, StringLength(60)]
    public string PropertyType { get; set; } = "Daire";

    [Required, StringLength(20)]
    public string ListingPurpose { get; set; } = "Kiralik";

    [Required, StringLength(40)]
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

    [Required, StringLength(60)]
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

    [Required]
    public string ImageUrl { get; set; } = string.Empty;
    public string ImageGalleryJson { get; set; } = "[]";

    public int OwnerUserId { get; set; }
    public string OwnerName { get; set; } = string.Empty;

    public bool IsRented { get; set; }
    public DateTime? RentedAt { get; set; }

    public bool IsDailyRecommended { get; set; }
    public bool IsAdminRecommended { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
