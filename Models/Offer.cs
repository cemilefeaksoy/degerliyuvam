using System.ComponentModel.DataAnnotations;

namespace Degerliyuvam.Models;

public enum OfferStatus
{
    Pending = 0,
    Accepted = 1,
    Rejected = 2
}

public enum OfferType
{
    PriceOffer = 0,
    RentalRequest = 1
}

public class Offer
{
    public int Id { get; set; }
    public int ListingId { get; set; }
    public int FromUserId { get; set; }
    public int ToOwnerUserId { get; set; }

    public decimal Amount { get; set; }

    [StringLength(600)]
    public string Note { get; set; } = string.Empty;

    public OfferType Type { get; set; } = OfferType.PriceOffer;
    public string PaymentCardLast4 { get; set; } = string.Empty;

    public OfferStatus Status { get; set; } = OfferStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
