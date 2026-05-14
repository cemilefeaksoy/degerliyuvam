using System.ComponentModel.DataAnnotations;

namespace Degerliyuvam.Models;

public class User
{
    public int Id { get; set; }

    [Required, StringLength(80)]
    public string FullName { get; set; } = string.Empty;

    [Required, StringLength(120)]
    public string Email { get; set; } = string.Empty;

    [Required, StringLength(20)]
    public string PhoneNumber { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;

    public UserRole Role { get; set; } = UserRole.Customer;

    [StringLength(400)]
    public string Bio { get; set; } = string.Empty;

    public string ProfileImageUrl { get; set; } = "/img/seed-8.jpeg";

    // Customers must be approved by admin before creating listings.
    public bool IsSellerApproved { get; set; }
}
