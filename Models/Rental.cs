namespace Degerliyuvam.Models;

public class Rental
{
    public int Id { get; set; }
    public int ListingId { get; set; }
    public int RenterUserId { get; set; }
    public int? ApprovedOfferId { get; set; }
    public string PaymentCardLast4 { get; set; } = string.Empty;
    public DateTime RentedAt { get; set; } = DateTime.UtcNow;
}
