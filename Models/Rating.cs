using System.ComponentModel.DataAnnotations;

namespace Degerliyuvam.Models;

public class Rating
{
    public int Id { get; set; }
    public int ListingId { get; set; }
    public int SellerUserId { get; set; }
    public int RenterUserId { get; set; }

    [Range(1, 5)]
    public int ListingScore { get; set; }

    [Range(1, 5)]
    public int SellerScore { get; set; }

    [StringLength(400)]
    public string Comment { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
