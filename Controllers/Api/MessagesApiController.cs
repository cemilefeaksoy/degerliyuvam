using Degerliyuvam.Models;
using Degerliyuvam.Services;
using Microsoft.AspNetCore.Mvc;

namespace Degerliyuvam.Controllers.Api;

[ApiController]
[Route("api/messages")]
public class MessagesApiController : ControllerBase
{
    private readonly AppService _appService;

    public MessagesApiController(AppService appService)
    {
        _appService = appService;
    }

    [HttpGet("inbox")]
    public IActionResult Inbox()
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        return Ok(_appService.GetInboxConversations(userId.Value));
    }

    [HttpGet("conversation/{withUserId:int}")]
    public IActionResult Conversation(int withUserId)
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        var other = _appService.GetUser(withUserId);
        if (other is null)
        {
            return NotFound(new { message = "Kullanici bulunamadi." });
        }

        _appService.MarkConversationAsRead(userId.Value, withUserId);
        var messages = _appService.GetConversation(userId.Value, withUserId);

        return Ok(new
        {
            otherUser = new
            {
                other.Id,
                other.FullName,
                other.PhoneNumber,
                other.Bio,
                other.ProfileImageUrl,
                other.Role,
                other.IsSellerApproved
            },
            messages,
            unreadCount = _appService.GetUnreadCount(userId.Value)
        });
    }

    [HttpPost("send")]
    public IActionResult Send([FromBody] SendMessageRequest request)
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        if (string.IsNullOrWhiteSpace(request.Content) && string.IsNullOrWhiteSpace(request.ImageUrl))
        {
            return BadRequest(new { message = "Boş mesaj gönderilemez." });
        }

        try
        {
            var message = _appService.SendMessage(userId.Value, request.ToUserId, request.Content, request.ImageUrl, request.OfferId);
            return Ok(message);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{messageId:int}")]
    public IActionResult Edit(int messageId, [FromBody] EditMessageRequest request)
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        try
        {
            _appService.EditMessage(messageId, userId.Value, request.Content);
            return Ok(new { message = "Mesaj düzenlendi." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{messageId:int}")]
    public IActionResult Delete(int messageId)
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        try
        {
            _appService.DeleteMessage(messageId, userId.Value);
            return Ok(new { message = "Mesaj silindi." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("unread-count")]
    public IActionResult UnreadCount()
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (!userId.HasValue)
        {
            return Ok(new { unreadCount = 0 });
        }

        return Ok(new { unreadCount = _appService.GetUnreadCount(userId.Value) });
    }

    [HttpGet("latest-unread")]
    public IActionResult LatestUnread()
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (!userId.HasValue)
        {
            return Unauthorized(new { message = "Oturum bulunamadi." });
        }

        var message = _appService.GetLatestUnreadMessage(userId.Value);
        return message is null ? Ok(null) : Ok(message);
    }
}

public class SendMessageRequest
{
    public int ToUserId { get; set; }
    public string Content { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public int? OfferId { get; set; }
}

public class EditMessageRequest
{
    public string Content { get; set; } = string.Empty;
}
