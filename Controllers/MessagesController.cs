using Degerliyuvam.Services;
using Degerliyuvam.ViewModels;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers;

public class MessagesController : Controller
{
    private readonly AppService _appService;
    private readonly IWebHostEnvironment _environment;

    public MessagesController(AppService appService, IWebHostEnvironment environment)
    {
        _appService = appService;
        _environment = environment;
    }

    public IActionResult Inbox()
    {
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue) return RedirectToAction("Login", "Account");

        var conversations = _appService.GetInboxConversations(userId.Value);

        return View(new InboxViewModel
        {
            Conversations = conversations,
            CurrentUserId = userId.Value,
            IsAdmin = AuthSession.IsAdmin(this)
        });
    }

    public IActionResult Chat(int withUserId)
    {
        var currentUserId = AuthSession.UserId(this);
        if (!currentUserId.HasValue) return RedirectToAction("Login", "Account");
        if (currentUserId.Value == withUserId) return RedirectToAction(nameof(Inbox));

        var other = _appService.GetUser(withUserId);
        if (other is null) return NotFound();

        _appService.MarkConversationAsRead(currentUserId.Value, withUserId);

        var vm = new ChatThreadViewModel
        {
            OtherUser = other,
            CurrentUserId = currentUserId.Value,
            Messages = _appService.GetConversation(currentUserId.Value, withUserId)
        };

        ViewBag.WithUserId = withUserId;
        return View(vm);
    }

    [HttpPost]
    public IActionResult Send(int withUserId, string? content, IFormFile? imageFile)
    {
        var currentUserId = AuthSession.UserId(this);
        if (!currentUserId.HasValue)
        {
            if (WantsJson()) return Unauthorized(new { ok = false, error = "Giris gerekli." });
            return RedirectToAction("Login", "Account");
        }
        if (currentUserId.Value == withUserId)
        {
            if (WantsJson()) return BadRequest(new { ok = false, error = "Gecersiz alici." });
            return RedirectToAction(nameof(Inbox));
        }

        var normalizedContent = (content ?? string.Empty).Trim();
        string? imageUrl = null;

        if (imageFile is not null && imageFile.Length > 0)
        {
            if (!TrySaveChatImage(imageFile, out imageUrl, out var uploadError))
            {
                if (WantsJson()) return BadRequest(new { ok = false, error = uploadError });
                TempData["Error"] = uploadError;
                return RedirectToAction(nameof(Chat), new { withUserId });
            }
        }

        if (string.IsNullOrWhiteSpace(normalizedContent) && string.IsNullOrWhiteSpace(imageUrl))
        {
            if (WantsJson()) return BadRequest(new { ok = false, error = "Bos mesaj gonderilemez." });
            TempData["Error"] = "Bos mesaj gonderilemez.";
            return RedirectToAction(nameof(Chat), new { withUserId });
        }

        var message = _appService.SendMessage(currentUserId.Value, withUserId, normalizedContent, imageUrl);
        if (WantsJson())
        {
            return Json(new
            {
                ok = true,
                message = ProjectMessage(message, currentUserId.Value)
            });
        }

        return RedirectToAction(nameof(Chat), new { withUserId });
    }

    [HttpPost]
    public IActionResult Edit(int withUserId, int messageId, string content)
    {
        var currentUserId = AuthSession.UserId(this);
        if (!currentUserId.HasValue) return Unauthorized(new { ok = false, error = "Giris gerekli." });
        if (currentUserId.Value == withUserId) return BadRequest(new { ok = false, error = "Gecersiz alici." });

        try
        {
            _appService.EditMessage(messageId, currentUserId.Value, content);
            return Json(new { ok = true });
        }
        catch (Exception ex)
        {
            return BadRequest(new { ok = false, error = ex.Message });
        }
    }

    [HttpPost]
    public IActionResult Delete(int withUserId, int messageId)
    {
        var currentUserId = AuthSession.UserId(this);
        if (!currentUserId.HasValue) return Unauthorized(new { ok = false, error = "Giris gerekli." });
        if (currentUserId.Value == withUserId) return BadRequest(new { ok = false, error = "Gecersiz alici." });

        try
        {
            _appService.DeleteMessage(messageId, currentUserId.Value);
            return Json(new { ok = true });
        }
        catch (Exception ex)
        {
            return BadRequest(new { ok = false, error = ex.Message });
        }
    }

    [HttpGet]
    public IActionResult UnreadCount()
    {
        var userId = AuthSession.UserId(this);
        if (!userId.HasValue)
        {
            return Json(new { unread = 0, latestUnreadMessageId = 0, fromName = "", preview = "" });
        }

        var latest = _appService.GetLatestUnreadMessage(userId.Value);
        var fromName = latest is null ? string.Empty : (_appService.GetUser(latest.FromUserId)?.FullName ?? "Bilinmeyen");
        var preview = latest is null
            ? string.Empty
            : latest.IsDeleted
                ? "Bu mesaj silindi."
                : !string.IsNullOrWhiteSpace(latest.Content)
                    ? latest.Content
                    : (!string.IsNullOrWhiteSpace(latest.ImageUrl) ? "[Gorsel]" : string.Empty);

        return Json(new
        {
            unread = _appService.GetUnreadCount(userId.Value),
            latestUnreadMessageId = latest?.Id ?? 0,
            fromName,
            preview
        });
    }

    [HttpGet]
    public IActionResult Conversation(int withUserId)
    {
        var currentUserId = AuthSession.UserId(this);
        if (!currentUserId.HasValue) return Unauthorized();

        _appService.MarkConversationAsRead(currentUserId.Value, withUserId);

        var messages = _appService.GetConversation(currentUserId.Value, withUserId)
            .Select(m => ProjectMessage(m, currentUserId.Value));

        return Json(messages);
    }

    private static object ProjectMessage(Degerliyuvam.Models.Message m, int currentUserId)
        => new
        {
            id = m.Id,
            fromUserId = m.FromUserId,
            content = m.Content,
            imageUrl = m.ImageUrl,
            isDeleted = m.IsDeleted,
            isEdited = m.IsEdited,
            canManage = m.FromUserId == currentUserId,
            createdAt = m.CreatedAt.ToLocalTime().ToString("dd.MM.yyyy HH:mm")
        };

    private bool WantsJson()
        => Request.Headers.Accept.Any(x => x?.Contains("application/json", StringComparison.OrdinalIgnoreCase) == true)
           || string.Equals(Request.Headers["X-Requested-With"], "fetch", StringComparison.OrdinalIgnoreCase)
           || string.Equals(Request.Headers["X-Requested-With"], "XMLHttpRequest", StringComparison.OrdinalIgnoreCase);

    private bool TrySaveChatImage(IFormFile file, out string? path, out string? error)
    {
        path = null;
        error = null;

        const long maxBytes = 8 * 1024 * 1024;
        if (file.Length > maxBytes)
        {
            error = "Resim boyutu en fazla 8 MB olabilir.";
            return false;
        }

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" };
        if (!allowed.Contains(ext))
        {
            error = "Sadece .jpg, .jpeg, .png, .webp, .gif dosyalari kabul edilir.";
            return false;
        }

        var uploadsPath = Path.Combine(_environment.WebRootPath, "img", "uploads", "messages");
        Directory.CreateDirectory(uploadsPath);

        var fileName = $"msg-{Guid.NewGuid():N}{ext}";
        var fullPath = Path.Combine(uploadsPath, fileName);

        using var stream = System.IO.File.Create(fullPath);
        file.CopyTo(stream);

        path = $"/img/uploads/messages/{fileName}";
        return true;
    }
}
