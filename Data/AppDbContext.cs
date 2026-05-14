using Degerliyuvam.Models;
using Microsoft.EntityFrameworkCore;

namespace Degerliyuvam.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Listing> Listings => Set<Listing>();
    public DbSet<Comment> Comments => Set<Comment>();
    public DbSet<Rating> Ratings => Set<Rating>();
    public DbSet<Rental> Rentals => Set<Rental>();
    public DbSet<Message> Messages => Set<Message>();
    public DbSet<Offer> Offers => Set<Offer>();
}
