using Degerliyuvam.Services;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers.Api;

[ApiController]
[Route("api/[controller]")]
public class ListingsApiController : ControllerBase
{
    private readonly AppService _appService;

    public ListingsApiController(AppService appService)
    {
        _appService = appService;
    }

    [HttpGet]
    public IActionResult GetAll() => Ok(_appService.GetListings());

    [HttpGet("{id:int}")]
    public IActionResult GetById(int id)
    {
        var listing = _appService.GetListing(id);
        return listing is null ? NotFound() : Ok(listing);
    }
}
