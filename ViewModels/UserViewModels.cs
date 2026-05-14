using System.ComponentModel.DataAnnotations;
using Degerliyuvam.Models;
using Microsoft.AspNetCore.Http;

namespace Degerliyuvam.ViewModels;

public class ProfileEditViewModel
{
    [Required, StringLength(80)]
    public string FullName { get; set; } = string.Empty;

    [StringLength(400)]
    public string Bio { get; set; } = string.Empty;

    public string ProfileImageUrl { get; set; } = string.Empty;
    public IFormFile? ProfileImageFile { get; set; }
}

public class UserAdminEditViewModel
{
    public int Id { get; set; }

    [Required, StringLength(80)]
    public string FullName { get; set; } = string.Empty;

    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    public UserRole Role { get; set; } = UserRole.Customer;
    public bool IsSellerApproved { get; set; }

    [StringLength(400)]
    public string Bio { get; set; } = string.Empty;

    public string ProfileImageUrl { get; set; } = string.Empty;
}
