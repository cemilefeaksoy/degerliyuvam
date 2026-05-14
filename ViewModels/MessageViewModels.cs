using Degerliyuvam.Models;

namespace Degerliyuvam.ViewModels;

public class ChatThreadViewModel
{
    public User OtherUser { get; set; } = new();
    public List<Message> Messages { get; set; } = new List<Message>();
    public int CurrentUserId { get; set; }
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
