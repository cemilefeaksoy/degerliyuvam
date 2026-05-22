using Degerliyuvam.Models;

namespace Degerliyuvam.ViewModels;

public class ChatThreadViewModel
{
    public User OtherUser { get; set; } = new();
    public List<Message> Messages { get; set; } = new List<Message>();
    public Dictionary<int, OfferMessageActionViewModel> OfferActionsByMessageId { get; set; } = new Dictionary<int, OfferMessageActionViewModel>();
    public int CurrentUserId { get; set; }
}

public class OfferMessageActionViewModel
{
    public int OfferId { get; set; }
    public int ListingId { get; set; }
    public string ListingTitle { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public OfferType OfferType { get; set; }
    public OfferStatus OfferStatus { get; set; }
    public bool CanRespond { get; set; }
    public string StatusLabel { get; set; } = string.Empty;
}

public class InboxConversationItemViewModel
{
    public int PartnerUserId { get; set; }
    public string PartnerName { get; set; } = string.Empty;
    public UserRole PartnerRole { get; set; }
    public string LastMessage { get; set; } = string.Empty;
    public DateTime LastMessageAt { get; set; }
    public int UnreadCount { get; set; }
    public bool LastFromMe { get; set; }
}

public class InboxViewModel
{
    public List<InboxConversationItemViewModel> Conversations { get; set; } = new List<InboxConversationItemViewModel>();
    public int CurrentUserId { get; set; }
    public bool IsAdmin { get; set; }
}
