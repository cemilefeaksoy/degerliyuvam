using System.ComponentModel.DataAnnotations;

namespace Degerliyuvam.Models;

public class Comment
{
    public int Id { get; set; }
    public int ListingId { get; set; }

    [Required, StringLength(80)]
    public string AuthorName { get; set; } = string.Empty;

    [Required, StringLength(500)]
    public string Content { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
