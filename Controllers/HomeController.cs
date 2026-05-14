using Degerliyuvam.Services;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers;

public class HomeController : Controller
{
    private readonly AppService _appService;

    public HomeController(AppService appService)
    {
        _appService = appService;
    }

    public IActionResult Index()
    {
        ViewBag.UserName = AuthSession.UserName(this);
        var allListings = _appService.GetListings();
        var allUsers    = _appService.GetUsers();

        var featured = allListings.Take(4).ToList();

        var adminRecommended = allListings
            .Where(x => x.IsAdminRecommended)
            .Take(8)
            .ToList();
        if (adminRecommended.Count == 0)
            adminRecommended = allListings.Skip(4).Take(8).ToList();

        ViewBag.AdminRecommended = adminRecommended;
        ViewBag.TotalListings    = allListings.Count;
        ViewBag.TotalCities      = allListings.Select(x => x.Province).Distinct().Count();
        ViewBag.TotalUsers       = allUsers.Count;

        return View(featured);
    }

    public IActionResult About()   => View();
    public IActionResult Contact() => View();
    public IActionResult Faq()     => View();
    public IActionResult Privacy() => View();
}
