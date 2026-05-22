using System.ComponentModel.DataAnnotations;
using Degerliyuvam.Models;
using Microsoft.AspNetCore.Http;

namespace Degerliyuvam.ViewModels;

public class ProfileEditViewModel
{
    [Required, StringLength(80)]
    public string FullName { get; set; } = string.Empty;

    [StringLength(20, MinimumLength = 10)]
    public string PhoneNumber { get; set; } = string.Empty;

    [StringLength(400)]
    public string Bio { get; set; } = string.Empty;

    public string ProfileImageUrl { get; set; } = string.Empty;
    public IFormFile? ProfileImageFile { get; set; }

    [DataType(DataType.Password)]
    public string CurrentPassword { get; set; } = string.Empty;

    [DataType(DataType.Password)]
    public string NewPassword { get; set; } = string.Empty;

    [DataType(DataType.Password)]
    [Compare(nameof(NewPassword), ErrorMessage = "Yeni sifreler ayni olmali.")]
    public string ConfirmNewPassword { get; set; } = string.Empty;
}

public class UserAdminEditViewModel
{
    public int Id { get; set; }

    [Required, StringLength(80)]
    public string FullName { get; set; } = string.Empty;

    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    [StringLength(20, MinimumLength = 10)]
    public string PhoneNumber { get; set; } = string.Empty;

    public UserRole Role { get; set; } = UserRole.Customer;
    public bool IsSellerApproved { get; set; }

    [StringLength(400)]
    public string Bio { get; set; } = string.Empty;

    public string ProfileImageUrl { get; set; } = string.Empty;

    [DataType(DataType.Password)]
    public string NewPassword { get; set; } = string.Empty;

    [DataType(DataType.Password)]
    [Compare(nameof(NewPassword), ErrorMessage = "Yeni sifreler ayni olmali.")]
    public string ConfirmNewPassword { get; set; } = string.Empty;
}

public class UserAdminCreateViewModel
{
    [Required, StringLength(80)]
    public string FullName { get; set; } = string.Empty;

    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required, StringLength(20, MinimumLength = 10)]
    public string PhoneNumber { get; set; } = string.Empty;

    [Required, MinLength(6)]
    [DataType(DataType.Password)]
    public string Password { get; set; } = string.Empty;

    [Required]
    [DataType(DataType.Password)]
    [Compare(nameof(Password), ErrorMessage = "Sifreler ayni olmali.")]
    public string ConfirmPassword { get; set; } = string.Empty;

    public UserRole Role { get; set; } = UserRole.Customer;
    public bool IsSellerApproved { get; set; } = true;

    [StringLength(400)]
    public string Bio { get; set; } = string.Empty;

    public string ProfileImageUrl { get; set; } = string.Empty;
}
