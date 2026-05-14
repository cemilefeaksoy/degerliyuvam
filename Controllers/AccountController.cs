using Degerliyuvam.Services;
using Degerliyuvam.ViewModels;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers;

public class AccountController : Controller
{
    private readonly AppService _appService;

    public AccountController(AppService appService)
    {
        _appService = appService;
    }

    [HttpGet]
    public IActionResult Login() => View(new LoginViewModel());

    [HttpPost]
    public IActionResult Login(LoginViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var user = _appService.Login(model.Email, model.Password);
        if (user is null)
        {
            ModelState.AddModelError(string.Empty, "E-posta veya sifre hatali.");
            return View(model);
        }

        AuthSession.SignIn(this, user, model.RememberMe);
        return RedirectToAction("Index", "Listings");
    }

    [HttpGet]
    public IActionResult Register() => View(new RegisterViewModel());

    [HttpPost]
    public IActionResult Register(RegisterViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        try
        {
            var user = _appService.Register(model.FullName, model.Email, model.PhoneNumber, model.Password);
            AuthSession.SignIn(this, user, model.RememberMe);
            return RedirectToAction("Index", "Listings");
        }
        catch (Exception ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(model);
        }
    }

    public IActionResult Logout()
    {
        AuthSession.SignOut(this);
        return RedirectToAction("Index", "Home");
    }
}
