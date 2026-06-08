using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers.Api;

[ApiController]
[Route("api/uploads")]
public class UploadsApiController : ControllerBase
{
    private static readonly HashSet<string> AllowedExtensions =
        new(StringComparer.OrdinalIgnoreCase) { ".jpg", ".jpeg", ".png", ".webp", ".gif" };

    private readonly IWebHostEnvironment _environment;

    public UploadsApiController(IWebHostEnvironment environment)
    {
        _environment = environment;
    }

    [HttpPost("image")]
    [RequestSizeLimit(8 * 1024 * 1024)]
    public async Task<IActionResult> UploadImage(IFormFile? file, [FromQuery] string category = "listings")
    {
        if (!HttpContext.Session.GetInt32("UserId").HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        if (file is null || file.Length == 0)
        {
            return BadRequest(new { message = "Bir görsel dosyası seçin." });
        }

        if (file.Length > 8 * 1024 * 1024)
        {
            return BadRequest(new { message = "Görsel boyutu en fazla 8 MB olabilir." });
        }

        var extension = Path.GetExtension(file.FileName);
        if (!AllowedExtensions.Contains(extension))
        {
            return BadRequest(new { message = "Sadece JPG, PNG, WEBP veya GIF yüklenebilir." });
        }

        var safeCategory = category.ToLowerInvariant() switch
        {
            "messages" => "messages",
            "profiles" => "profiles",
            _ => "listings"
        };
        var directory = Path.Combine(_environment.WebRootPath, "img", "uploads", safeCategory);
        Directory.CreateDirectory(directory);

        var prefix = safeCategory switch
        {
            "messages" => "msg",
            "profiles" => "profile",
            _ => "listing"
        };
        var fileName = $"{prefix}-{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
        var fullPath = Path.Combine(directory, fileName);

        await using var stream = System.IO.File.Create(fullPath);
        await file.CopyToAsync(stream);

        return Ok(new { url = $"/img/uploads/{safeCategory}/{fileName}" });
    }
}
