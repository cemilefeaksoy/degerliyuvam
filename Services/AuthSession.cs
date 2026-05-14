using Degerliyuvam.Models;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Services;

public static class AuthSession
{
    public static void SignIn(Controller controller, User user, bool rememberMe)
    {
        controller.HttpContext.Session.SetInt32("UserId", user.Id);
        controller.HttpContext.Session.SetString("UserName", user.FullName);
        controller.HttpContext.Session.SetString("Role", user.Role.ToString());

        if (!rememberMe)
        {
            controller.HttpContext.Response.Cookies.Delete("DegerliyuvamRemember");
            controller.HttpContext.Response.Cookies.Delete("DegerliyuvamRemember");
            return;
        }

        var cookieOptions = new CookieOptions
        {
            Expires = DateTimeOffset.UtcNow.AddDays(180),
            HttpOnly = true,
            IsEssential = true
        };

        controller.HttpContext.Response.Cookies.Append("DegerliyuvamRemember", user.Email, cookieOptions);
    }

    public static void SignOut(Controller controller)
    {
        controller.HttpContext.Session.Clear();
        controller.HttpContext.Response.Cookies.Delete("DegerliyuvamRemember");
        controller.HttpContext.Response.Cookies.Delete("DegerliyuvamRemember");
    }

    public static int? UserId(Controller controller) => controller.HttpContext.Session.GetInt32("UserId");
    public static string? UserName(Controller controller) => controller.HttpContext.Session.GetString("UserName");

    public static UserRole? Role(Controller controller)
    {
        var value = controller.HttpContext.Session.GetString("Role");
        return Enum.TryParse<UserRole>(value, out var role) ? role : null;
    }

    public static bool IsLoggedIn(Controller controller) => UserId(controller).HasValue;
    public static bool IsAdmin(Controller controller) => Role(controller) == UserRole.Admin;
}
