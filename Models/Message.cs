using System.ComponentModel.DataAnnotations;

namespace Degerliyuvam.Models;

public class Message
{
    public int Id { get; set; }
    public int FromUserId { get; set; }
    public int ToUserId { get; set; }

    [StringLength(1000)]
    public string Content { get; set; } = string.Empty;

    [StringLength(300)]
    public string ImageUrl { get; set; } = string.Empty;
    public int? OfferId { get; set; }

    public bool IsRead { get; set; }
    public bool IsDeleted { get; set; }
    public bool IsEdited { get; set; }
    public DateTime? EditedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
