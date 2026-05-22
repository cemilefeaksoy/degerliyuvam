using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Degerliyuvam.Data;
using Degerliyuvam.Models;
using Degerliyuvam.ViewModels;
using Microsoft.EntityFrameworkCore;

namespace Degerliyuvam.Services;

public class AppService
{
    private readonly AppDbContext _db;
    public const string SuperAdminEmail = "mobieefe@gmail.com";

    private static readonly Dictionary<string, List<string>> _locations = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase)
    {
        ["Istanbul"] = new List<string> { "Besiktas", "Kadikoy", "Sisli", "Uskudar", "Bakirkoy", "Beylikduzu", "Sariyer", "Ataşehir" },
        ["Ankara"] = new List<string> { "Cankaya", "Yenimahalle", "Kecioren", "Etimesgut", "Mamak", "Golbasi", "Pursaklar" },
        ["Izmir"] = new List<string> { "Karsiyaka", "Bornova", "Konak", "Buca", "Balcova", "Bayrakli", "Guzelbahce" },
        ["Bursa"] = new List<string> { "Nilufer", "Osmangazi", "Yildirim", "Mudanya", "Gursu", "Inegol" },
        ["Antalya"] = new List<string> { "Muratpasa", "Konyaalti", "Kepez", "Lara", "Dosemealti", "Alanya" },
        ["Adana"] = new List<string> { "Cukurova", "Seyhan", "Yuregir", "Sarıçam", "Karatas" },
        ["Konya"] = new List<string> { "Selcuklu", "Meram", "Karatay", "Eregli", "Beyşehir" },
        ["Gaziantep"] = new List<string> { "Sahinbey", "Sehitkamil", "Oguzeli", "Nizip", "Islahiye" },
        ["Kocaeli"] = new List<string> { "Izmit", "Gebze", "Basiskele", "Derince", "Golcuk" },
        ["Mersin"] = new List<string> { "Mezitli", "Yenişehir", "Toroslar", "Tarsus", "Erdemli" },
        ["Kayseri"] = new List<string> { "Melikgazi", "Kocasinan", "Talas", "Develi", "Yesilhisar" },
        ["Eskişehir"] = new List<string> { "Tepebasi", "Odunpazari", "Sivrihisar", "Inonu" },
        ["Samsun"] = new List<string> { "Atakum", "İlkadim", "Canik", "Bafra", "Carsamba" },
        ["Trabzon"] = new List<string> { "Ortahisar", "Yomra", "Akcaabat", "Arsin", "Vakfikebir" },
        ["Diyarbakir"] = new List<string> { "Baglar", "Kayapinar", "Yenişehir", "Sur", "Bismil" },
        ["Sanliurfa"] = new List<string> { "Haliliye", "Eyyubiye", "Karakopru", "Siverek", "Viranşehir" },
        ["Erzurum"] = new List<string> { "Yakutiye", "Palandoken", "Aziziye", "Horasan", "Oltu" },
        ["Malatya"] = new List<string> { "Battalgazi", "Yesilyurt", "Akcadag", "Darende", "Doğanşehir" },
        ["Manisa"] = new List<string> { "Sehzadeler", "Yunusemre", "Turgutlu", "Salihli", "Akhisar" },
        ["Balikesir"] = new List<string> { "Ayvalik", "Edremit", "Bandirma", "Karesi", "Altieylul" },
        ["Aydin"] = new List<string> { "Efeler", "Kusadasi", "Didim", "Nazilli", "Soke" },
        ["Mugla"] = new List<string> { "Bodrum", "Fethiye", "Marmaris", "Milas", "Datca" },
        ["Tekirdag"] = new List<string> { "Suleymanpasa", "Corlu", "Cerkezkoy", "Malkara", "Saray" },
        ["Sakarya"] = new List<string> { "Adapazari", "Serdivan", "Akyazi", "Sapanca", "Karasu" },
        ["Denizli"] = new List<string> { "Pamukkale", "Merkezefendi", "Acipayam", "Saraykoy", "Tavas" },
        ["Hatay"] = new List<string> { "Antakya", "Defne", "Iskenderun", "Samandag", "Dortyol" },
        ["Kahramanmaras"] = new List<string> { "Onikisubat", "Dulkadiroglu", "Elbistan", "Afshin", "Turkoglu" },
        ["Van"] = new List<string> { "Ipekyolu", "Edremit", "Tusba", "Ercis", "Gevas" },
        ["Ordu"] = new List<string> { "Altinordu", "Unye", "Fatsa", "Persembe", "Kumru" },
        ["Sivas"] = new List<string> { "Merkez", "Susehri", "Yildizeli", "Sarkisla", "Zara" }
    };

    public AppService(AppDbContext db)
    {
        _db = db;
        _db.Database.EnsureCreated();
        EnsureSchemaUpgrades();
        Seed();
    }

    public IReadOnlyDictionary<string, List<string>> GetLocationMap() => _locations;

    private static string BuildCity(string province, string district)
        => string.IsNullOrWhiteSpace(district) ? province : $"{province} / {district}";

    private static string NormalizeEmail(string email)
        => (email ?? string.Empty).Trim();

    private static string NormalizePassword(string password)
        => (password ?? string.Empty).Trim();

    private static string HashPassword(string password)
    {
        using var sha256 = SHA256.Create();
        var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
        return BitConverter.ToString(bytes).Replace("-", string.Empty);
    }

    private bool VerifyPassword(string inputPassword, string storedHash)
    {
        if (string.IsNullOrWhiteSpace(storedHash))
        {
            return false;
        }

        var rawInput = inputPassword ?? string.Empty;
        var hashedInput = HashPassword(rawInput);
        if (string.Equals(hashedInput, storedHash, StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        var trimmedInput = NormalizePassword(rawInput);
        if (!string.Equals(trimmedInput, rawInput, StringComparison.Ordinal))
        {
            var trimmedHash = HashPassword(trimmedInput);
            if (string.Equals(trimmedHash, storedHash, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        // Legacy compatibility: older records may still contain plaintext passwords.
        return string.Equals(rawInput, storedHash, StringComparison.Ordinal)
            || string.Equals(trimmedInput, storedHash, StringComparison.Ordinal);
    }

    private static bool IsSuperAdminEmail(string? email)
        => string.Equals(NormalizeEmail(email ?? string.Empty), SuperAdminEmail, StringComparison.OrdinalIgnoreCase);

    private void EnsureSchemaUpgrades()
    {
        // Lightweight compatibility upgrade for existing SQLite files without migrations.
        AddColumnIfMissing("Messages", "ImageUrl", "TEXT NOT NULL DEFAULT ''");
        AddColumnIfMissing("Messages", "IsDeleted", "INTEGER NOT NULL DEFAULT 0");
        AddColumnIfMissing("Messages", "IsEdited", "INTEGER NOT NULL DEFAULT 0");
        AddColumnIfMissing("Messages", "EditedAt", "TEXT NULL");
        AddColumnIfMissing("Messages", "OfferId", "INTEGER NULL");
        AddColumnIfMissing("Listings", "ImageGalleryJson", "TEXT NOT NULL DEFAULT '[]'");
        AddColumnIfMissing("Users", "PhoneNumber", "TEXT NOT NULL DEFAULT ''");
        AddColumnIfMissing("Listings", "ListingPurpose", "TEXT NOT NULL DEFAULT 'Kiralık'");
        AddColumnIfMissing("Listings", "IsDailyRecommended", "INTEGER NOT NULL DEFAULT 0");
        TryExec("""
            CREATE TABLE IF NOT EXISTS Ratings (
                Id INTEGER NOT NULL CONSTRAINT PK_Ratings PRIMARY KEY AUTOINCREMENT,
                ListingId INTEGER NOT NULL,
                SellerUserId INTEGER NOT NULL,
                RenterUserId INTEGER NOT NULL,
                ListingScore INTEGER NOT NULL,
                SellerScore INTEGER NOT NULL,
                Comment TEXT NOT NULL DEFAULT '',
                CreatedAt TEXT NOT NULL
            );
            """);
        TryExec("CREATE UNIQUE INDEX IF NOT EXISTS IX_Ratings_Listing_Renter ON Ratings(ListingId, RenterUserId);");
    }

    private void AddColumnIfMissing(string tableName, string columnName, string columnDefinition)
    {
        if (ColumnExists(tableName, columnName))
        {
            return;
        }

        TryExec($"ALTER TABLE {tableName} ADD COLUMN {columnName} {columnDefinition};");
    }

    private bool ColumnExists(string tableName, string columnName)
    {
        var connection = _db.Database.GetDbConnection();
        var shouldClose = connection.State == System.Data.ConnectionState.Closed;

        if (shouldClose)
        {
            connection.Open();
        }

        try
        {
            using var command = connection.CreateCommand();
            command.CommandText = $"PRAGMA table_info({tableName});";
            using var reader = command.ExecuteReader();
            while (reader.Read())
            {
                if (string.Equals(reader.GetString(1), columnName, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }

            return false;
        }
        finally
        {
            if (shouldClose)
            {
                connection.Close();
            }
        }
    }

    private void TryExec(string sql)
    {
        try
        {
            _db.Database.ExecuteSqlRaw(sql);
        }
        catch
        {
            // Existing column or legacy DB edge-case: ignore and keep app running.
        }
    }

    private void Seed()
    {
        var admin = EnsureSeedUser(
            "Sistem Yönetici",
            "mobieefe@gmail.com",
            "Admin123!",
            UserRole.Admin,
            "Platform yonetimi ve kalite kontrol.",
            "/img/seed-10.jpeg");

        var sellerA = EnsureSeedUser(
            "Demo Satıcı",
            "musteri@degerliyuvam.com",
            "Müşteri123!",
            UserRole.Customer,
            "Bosphorus bolgesinde premium kiralik portfoy yonetiyorum.",
            "/img/seed-8.jpeg");

        var sellerB = EnsureSeedUser(
            "Satıcı Elif",
            "elif@degerliyuvam.com",
            "Satıcı123!",
            UserRole.Customer,
            "Modern residence ve deniz manzarali ilanlar.",
            "/img/seed-9.jpeg");

        EnsureDemoListings(new List<User> { sellerA, sellerB }, admin.Id);
        _db.SaveChanges();
    }

    private User EnsureSeedUser(
        string fullName,
        string email,
        string password,
        UserRole role,
        string bio,
        string imageUrl,
        string phoneNumber = "05000000000")
    {
        var existing = _db.Users
            .AsEnumerable()
            .FirstOrDefault(x => string.Equals(NormalizeEmail(x.Email), NormalizeEmail(email), StringComparison.OrdinalIgnoreCase));

        if (existing is not null)
        {
            return existing;
        }

        var user = new User
        {
            FullName = fullName,
            Email = NormalizeEmail(email),
            PhoneNumber = phoneNumber,
            Password = HashPassword(password),
            Role = role,
            Bio = bio,
            ProfileImageUrl = imageUrl,
            IsSellerApproved = true
        };

        _db.Users.Add(user);
        _db.SaveChanges();
        return user;
    }

    private void EnsureDemoListings(List<User> owners, int adminUserId)
    {
        if (owners.Count == 0) return;

        var propertyTypes = new[] { "Daire", "Villa", "Rezidans", "Mustakil Ev", "Dublex" };
        var roomOptions = new[] { "1+1", "2+1", "3+1", "4+1", "5+1" };
        var heatOptions = new[] { "Kombi Doğalgaz", "Merkezi", "Yerden Isıtma", "Klima", "Isı Pompası" };
        var descriptionTemplates = new[]
        {
            "Sessiz sokakta, gun boyu isik alan planli bir yasam alani sunar.",
            "Toplu ulasima yurume mesafesinde, yeni mutfak ve yenilenmis banyoya sahip.",
            "Site icerisinde guvenlikli giris, sosyal alan ve cocuk parki avantajlari sunar.",
            "Geniş salonu, kullanışlı odaları ve ferah balkonu ile aile yaşamına uygundur.",
            "Market, okul ve hastane aksina yakin konumda konforlu bir kiralik secenektir.",
            "Modern cepheli binada, yuksek kira potansiyelli merkezi bir konumda yer alir.",
            "Acik otopark, asansor ve aidat dengesine sahip duzenli bir site dairesidir.",
            "Manzaraya acilan pencereleri ve depolama alani kuvvetli planiyla one cikar.",
            "Yeni boya, bakimli parkeler ve genis mutfakla tasinmaya hazir durumdadir.",
            "Sakin komsuluk yapisi ve ulasim kolayligi ile uzun sureli kiralama icin idealdir."
        };
        var lifestyleNotes = new[]
        {
            "Yakinda semt pazari ve butik kahve noktalarina erisim bulunur.",
            "Sahil hattina kisa surus mesafesiyle hafta sonu yasami destekler.",
            "Bolgede artan yeni proje yatirimlari kiralama talebini guclendiriyor.",
            "Yakin cevrede spor salonu, eczane ve market zincirleri yer aliyor.",
            "Metro ve ana arter baglantisi sayesinde is merkezlerine ulasim hizlidir."
        };

        var cityIndex = 0;
        var listingIndex = 0;

        foreach (var city in _locations)
        {
            var districtIndex = 0;
            foreach (var district in city.Value)
            {
                var type = propertyTypes[(cityIndex + districtIndex) % propertyTypes.Length];
                var room = roomOptions[(listingIndex + districtIndex) % roomOptions.Length];
                var title = $"Demo En Iyi Ev - {district} {type}";

                if (_db.Listings.Any(x => x.Title == title))
                {
                    districtIndex++;
                    listingIndex++;
                    continue;
                }

                var owner = owners[(cityIndex + districtIndex) % owners.Count];
                var gross = 90 + ((listingIndex * 7) % 95);
                var net = Math.Max(60, gross - 14);
                var monthlyPrice = 16000 + (cityIndex * 900) + (districtIndex * 1200) + ((listingIndex % 6) * 750);
                var deposit = monthlyPrice * 1.4m;
                var dues = 600 + ((listingIndex % 9) * 85);
                var desc = $"{descriptionTemplates[listingIndex % descriptionTemplates.Length]} " +
                           $"{district} bolgesinde konumlanan ilan, {lifestyleNotes[(listingIndex + 2) % lifestyleNotes.Length]}";

                var imageA = $"/img/seed-{(listingIndex % 12) + 1}.jpeg";
                var imageB = $"/img/seed-{((listingIndex + 1) % 12) + 1}.jpeg";
                var imageC = $"/img/seed-{((listingIndex + 2) % 12) + 1}.jpeg";

                _db.Listings.Add(new Listing
                {
                    Title = title,
                    Description = desc,
                    Province = city.Key,
                    District = district,
                    City = BuildCity(city.Key, district),
                    PropertyType = type,
                    ListingPurpose = listingIndex % 3 == 0 ? "Satılık" : "Kiralık",
                    RoomCount = room,
                    GrossSquareMeters = gross,
                    NetSquareMeters = net,
                    BuildingAge = (listingIndex + 3) % 18,
                    Floor = (listingIndex % 10) + 1,
                    TotalFloors = 10 + ((listingIndex + 2) % 8),
                    BathroomCount = (listingIndex % 3) + 1,
                    HeatingType = heatOptions[listingIndex % heatOptions.Length],
                    Furnished = listingIndex % 2 == 0,
                    Balcony = listingIndex % 4 != 1,
                    Elevator = true,
                    Parking = listingIndex % 3 == 0,
                    InSite = listingIndex % 5 != 0,
                    HasPool = listingIndex % 9 == 0,
                    MonthlyPrice = monthlyPrice,
                    Deposit = deposit,
                    Dues = dues,
                    ImageUrl = imageA,
                    ImageGalleryJson = JsonSerializer.Serialize(new[] { imageA, imageB, imageC }),
                    OwnerUserId = owner.Id,
                    OwnerName = owner.FullName,
                    IsDailyRecommended = false,
                    IsAdminRecommended = listingIndex % 7 == 0 && owner.Id != adminUserId,
                    IsRented = false,
                    CreatedAt = DateTime.UtcNow.AddDays(-listingIndex)
                });

                districtIndex++;
                listingIndex++;
            }

            cityIndex++;
        }
    }

    public User? Login(string email, string password)
    {
        var normalizedEmail = NormalizeEmail(email);
        var user = _db.Users
            .AsEnumerable()
            .FirstOrDefault(x => string.Equals(NormalizeEmail(x.Email), normalizedEmail, StringComparison.OrdinalIgnoreCase));
        if (user is null) return null;
        var valid = VerifyPassword(password, user.Password);
        if (!valid) return null;

        var hashedInput = HashPassword(NormalizePassword(password));
        if (!string.Equals(user.Password, hashedInput, StringComparison.OrdinalIgnoreCase))
        {
            user.Password = hashedInput;
            _db.SaveChanges();
        }

        return user;
    }

    public User Register(string fullName, string email, string phoneNumber, string password)
    {
        email = NormalizeEmail(email);
        password = NormalizePassword(password);
        if (_db.Users.AsEnumerable().Any(u => string.Equals(NormalizeEmail(u.Email), email, StringComparison.OrdinalIgnoreCase)))
        {
            throw new InvalidOperationException("Bu e-posta zaten kayitli.");
        }

        var user = new User
        {
            FullName = fullName,
            Email = email,
            PhoneNumber = (phoneNumber ?? string.Empty).Trim(),
            Password = HashPassword(password),
            Role = UserRole.Customer,
            Bio = string.Empty,
            ProfileImageUrl = "/img/seed-7.jpeg",
            IsSellerApproved = true
        };

        _db.Users.Add(user);
        _db.SaveChanges();
        return user;
    }

    public User CreateUserByAdmin(int actorUserId, UserAdminCreateViewModel model)
    {
        var actor = GetUser(actorUserId) ?? throw new InvalidOperationException("Yetkili kullanici bulunamadi.");
        var actorIsSuperAdmin = IsSuperAdminEmail(actor.Email);

        model.Email = NormalizeEmail(model.Email);
        model.Password = NormalizePassword(model.Password);

        if (_db.Users.AsEnumerable().Any(u => string.Equals(NormalizeEmail(u.Email), model.Email, StringComparison.OrdinalIgnoreCase)))
        {
            throw new InvalidOperationException("Bu e-posta zaten kayitli.");
        }

        if (model.Password.Length < 6)
        {
            throw new InvalidOperationException("Sifre en az 6 karakter olmalidir.");
        }

        if (model.Role == UserRole.Admin && !actorIsSuperAdmin)
        {
            throw new InvalidOperationException("Admin hesap olusturma yetkisi yalnizca super admindedir.");
        }

        var user = new User
        {
            FullName = model.FullName.Trim(),
            Email = model.Email,
            PhoneNumber = (model.PhoneNumber ?? string.Empty).Trim(),
            Password = HashPassword(model.Password),
            Role = model.Role,
            Bio = (model.Bio ?? string.Empty).Trim(),
            ProfileImageUrl = string.IsNullOrWhiteSpace(model.ProfileImageUrl) ? "/img/seed-8.jpeg" : model.ProfileImageUrl.Trim(),
            IsSellerApproved = model.Role == UserRole.Admin || model.IsSellerApproved
        };

        _db.Users.Add(user);
        _db.SaveChanges();
        return user;
    }

    public User? GetUser(int id) => _db.Users.FirstOrDefault(x => x.Id == id);
    public User? GetUserByEmail(string email)
    {
        var normalized = NormalizeEmail(email);
        return _db.Users
            .AsEnumerable()
            .FirstOrDefault(x => string.Equals(NormalizeEmail(x.Email), normalized, StringComparison.OrdinalIgnoreCase));
    }

    public List<User> GetUsers() => _db.Users.OrderBy(x => x.Role).ThenBy(x => x.FullName).ToList();
    public List<User> GetNonAdminUsers()
        => _db.Users
            .Where(x => x.Role != UserRole.Admin)
            .OrderBy(x => x.FullName)
            .ToList();
    public bool IsSuperAdmin(int userId)
    {
        var user = GetUser(userId);
        return user is not null && IsSuperAdminEmail(user.Email);
    }
    public List<Offer> GetOffers() => _db.Offers.OrderByDescending(x => x.CreatedAt).ToList();
    public List<Rental> GetRentals() => _db.Rentals.OrderByDescending(x => x.RentedAt).ToList();
    public List<Message> GetMessages() => _db.Messages.OrderByDescending(x => x.CreatedAt).ToList();
    public List<Comment> GetComments() => _db.Comments.OrderByDescending(x => x.CreatedAt).ToList();
    public List<Rating> GetRatings() => _db.Ratings.OrderByDescending(x => x.CreatedAt).ToList();

    public bool CanCreateListing(int userId)
    {
        var user = GetUser(userId);
        return user is not null;
    }

    public void UpdateUserProfile(int userId, string fullName, string phoneNumber, string bio, string? profileImageUrl)
    {
        var user = GetUser(userId) ?? throw new InvalidOperationException("Kullanici bulunamadi.");
        user.FullName = fullName.Trim();
        user.PhoneNumber = (phoneNumber ?? string.Empty).Trim();
        user.Bio = bio.Trim();

        if (!string.IsNullOrWhiteSpace(profileImageUrl))
        {
            user.ProfileImageUrl = profileImageUrl.Trim();
        }

        foreach (var listing in _db.Listings.Where(x => x.OwnerUserId == userId))
        {
            listing.OwnerName = user.FullName;
        }

        _db.SaveChanges();
    }

    public void ChangeOwnPassword(int userId, string currentPassword, string newPassword)
    {
        var user = GetUser(userId) ?? throw new InvalidOperationException("Kullanici bulunamadi.");
        if (!VerifyPassword(currentPassword, user.Password))
        {
            throw new InvalidOperationException("Mevcut sifre hatali.");
        }

        var next = NormalizePassword(newPassword);
        if (next.Length < 6)
        {
            throw new InvalidOperationException("Yeni sifre en az 6 karakter olmalidir.");
        }

        user.Password = HashPassword(next);
        _db.SaveChanges();
    }

    public void UpdateUserByAdmin(int actorUserId, UserAdminEditViewModel model)
    {
        var user = GetUser(model.Id) ?? throw new InvalidOperationException("Kullanici bulunamadi.");
        var actor = GetUser(actorUserId) ?? throw new InvalidOperationException("Yetkili kullanici bulunamadi.");
        var actorIsSuperAdmin = IsSuperAdminEmail(actor.Email);
        var targetIsSuperAdmin = IsSuperAdminEmail(user.Email);

        if (targetIsSuperAdmin && !actorIsSuperAdmin)
        {
            throw new InvalidOperationException("Super admin hesabi yalnizca super admin tarafindan duzenlenebilir.");
        }

        model.Email = NormalizeEmail(model.Email);
        var nextIsSuperAdmin = IsSuperAdminEmail(model.Email);
        if (targetIsSuperAdmin && !nextIsSuperAdmin)
        {
            throw new InvalidOperationException("Super admin e-posta adresi degistirilemez.");
        }

        if (_db.Users
            .AsEnumerable()
            .Any(x => x.Id != model.Id && string.Equals(NormalizeEmail(x.Email), model.Email, StringComparison.OrdinalIgnoreCase)))
        {
            throw new InvalidOperationException("Bu e-posta baska bir kullanici tarafindan kullaniliyor.");
        }

        if (!actorIsSuperAdmin && user.Role == UserRole.Admin && model.Role != UserRole.Admin)
        {
            throw new InvalidOperationException("Admin rolunu yalnizca super admin degistirebilir.");
        }

        if (!actorIsSuperAdmin && model.Role == UserRole.Admin && user.Role != UserRole.Admin)
        {
            throw new InvalidOperationException("Yeni admin atamasini yalnizca super admin yapabilir.");
        }

        user.FullName = model.FullName.Trim();
        user.Email = model.Email;
        user.Role = model.Role;
        user.Bio = model.Bio.Trim();
        user.IsSellerApproved = model.Role == UserRole.Admin || model.IsSellerApproved;

        if (!string.IsNullOrWhiteSpace(model.ProfileImageUrl))
        {
            user.ProfileImageUrl = model.ProfileImageUrl.Trim();
        }

        foreach (var listing in _db.Listings.Where(x => x.OwnerUserId == user.Id))
        {
            listing.OwnerName = user.FullName;
        }

        if (!string.IsNullOrWhiteSpace(model.NewPassword))
        {
            var nextPassword = NormalizePassword(model.NewPassword);
            if (nextPassword.Length < 6)
            {
                throw new InvalidOperationException("Yeni sifre en az 6 karakter olmalidir.");
            }

            user.Password = HashPassword(nextPassword);
        }

        _db.SaveChanges();
    }

    public void SetSellerApproval(int actorUserId, int userId, bool approved)
    {
        var user = GetUser(userId) ?? throw new InvalidOperationException("Kullanici bulunamadi.");
        var actor = GetUser(actorUserId) ?? throw new InvalidOperationException("Yetkili kullanici bulunamadi.");
        var actorIsSuperAdmin = IsSuperAdminEmail(actor.Email);
        var targetIsSuperAdmin = IsSuperAdminEmail(user.Email);

        if (targetIsSuperAdmin && !actorIsSuperAdmin)
        {
            throw new InvalidOperationException("Super admin hesabi duzenlenemez.");
        }

        if (user.Role == UserRole.Admin)
        {
            user.IsSellerApproved = true;
        }
        else
        {
            user.IsSellerApproved = approved;
        }

        _db.SaveChanges();
    }

    public void SetAdminRole(int actorUserId, int userId, bool makeAdmin)
    {
        var actor = GetUser(actorUserId) ?? throw new InvalidOperationException("Yetkili kullanici bulunamadi.");
        if (!IsSuperAdminEmail(actor.Email))
        {
            throw new InvalidOperationException("Admin rol atama/kaldirma islemi yalnizca super admin tarafindan yapilabilir.");
        }

        var user = GetUser(userId) ?? throw new InvalidOperationException("Kullanici bulunamadi.");
        var targetIsSuperAdmin = IsSuperAdminEmail(user.Email);
        if (makeAdmin)
        {
            user.Role = UserRole.Admin;
            user.IsSellerApproved = true;
        }
        else
        {
            if (targetIsSuperAdmin)
            {
                throw new InvalidOperationException("Super admin rolunden cikarilamaz.");
            }

            if (user.Role == UserRole.Admin)
            {
                var adminCount = _db.Users.Count(x => x.Role == UserRole.Admin);
                if (adminCount <= 1)
                {
                    throw new InvalidOperationException("Son adminin rolu kaldirilamaz.");
                }
            }

            user.Role = UserRole.Customer;
        }

        _db.SaveChanges();
    }

    public void DeleteUser(int actorUserId, int userId)
    {
        var user = GetUser(userId);
        if (user is null) return;
        var actor = GetUser(actorUserId) ?? throw new InvalidOperationException("Yetkili kullanici bulunamadi.");
        var actorIsSuperAdmin = IsSuperAdminEmail(actor.Email);
        var targetIsSuperAdmin = IsSuperAdminEmail(user.Email);

        if (targetIsSuperAdmin)
        {
            throw new InvalidOperationException("Super admin hesabi silinemez.");
        }

        if (user.Role == UserRole.Admin && !actorIsSuperAdmin)
        {
            throw new InvalidOperationException("Admin silme islemi yalnizca super admin tarafindan yapilabilir.");
        }

        if (user.Role == UserRole.Admin)
        {
            var adminCount = _db.Users.Count(x => x.Role == UserRole.Admin);
            if (adminCount <= 1)
            {
                throw new InvalidOperationException("Son admin silinemez.");
            }
        }

        var listingIds = _db.Listings.Where(x => x.OwnerUserId == userId).Select(x => x.Id).ToList();
        foreach (var listingId in listingIds)
        {
            DeleteListing(listingId);
        }

        var comments = _db.Comments.Where(x => x.AuthorName == user.FullName).ToList();
        _db.Comments.RemoveRange(comments);

        var rentals = _db.Rentals.Where(x => x.RenterUserId == userId).ToList();
        _db.Rentals.RemoveRange(rentals);

        var ratings = _db.Ratings.Where(x => x.RenterUserId == userId || x.SellerUserId == userId).ToList();
        _db.Ratings.RemoveRange(ratings);

        var messages = _db.Messages.Where(x => x.FromUserId == userId || x.ToUserId == userId).ToList();
        _db.Messages.RemoveRange(messages);

        var offers = _db.Offers.Where(x => x.FromUserId == userId || x.ToOwnerUserId == userId).ToList();
        _db.Offers.RemoveRange(offers);

        _db.Users.Remove(user);
        _db.SaveChanges();
    }

    public List<Listing> GetListings() => _db.Listings.OrderByDescending(x => x.CreatedAt).ToList();

    public Listing? GetListing(int id) => _db.Listings.FirstOrDefault(x => x.Id == id);

    public List<Listing> GetListingsByOwner(int ownerUserId)
        => _db.Listings.Where(x => x.OwnerUserId == ownerUserId).OrderByDescending(x => x.CreatedAt).ToList();

    public List<Listing> GetListingsRentedByUser(int renterUserId)
    {
        var listingIds = _db.Rentals
            .Where(x => x.RenterUserId == renterUserId)
            .OrderByDescending(x => x.RentedAt)
            .Select(x => x.ListingId)
            .ToList();

        if (listingIds.Count == 0)
        {
            return new List<Listing>();
        }

        var order = listingIds
            .Select((id, index) => new { id, index })
            .ToDictionary(x => x.id, x => x.index);

        return _db.Listings
            .Where(x => listingIds.Contains(x.Id))
            .AsEnumerable()
            .OrderBy(x => order.TryGetValue(x.Id, out var index) ? index : int.MaxValue)
            .ToList();
    }

    public List<Comment> GetCommentsByListing(int listingId)
        => _db.Comments.Where(x => x.ListingId == listingId).OrderByDescending(x => x.CreatedAt).ToList();

    public Listing CreateListing(Listing listing)
    {
        _ = GetUser(listing.OwnerUserId) ?? throw new InvalidOperationException("Kullanici bulunamadi.");

        listing.City = BuildCity(listing.Province, listing.District);
        listing.ListingPurpose = NormalizeListingPurpose(listing.ListingPurpose);
        listing.CreatedAt = DateTime.UtcNow;
        _db.Listings.Add(listing);
        _db.SaveChanges();
        return listing;
    }

    public void UpdateListing(Listing listing)
    {
        var existing = GetListing(listing.Id) ?? throw new InvalidOperationException("İlan bulunamadı.");
        existing.Title = listing.Title;
        existing.Description = listing.Description;
        existing.Province = listing.Province;
        existing.District = listing.District;
        existing.City = BuildCity(listing.Province, listing.District);
        existing.PropertyType = listing.PropertyType;
        existing.ListingPurpose = NormalizeListingPurpose(listing.ListingPurpose);
        existing.RoomCount = listing.RoomCount;
        existing.GrossSquareMeters = listing.GrossSquareMeters;
        existing.NetSquareMeters = listing.NetSquareMeters;
        existing.BuildingAge = listing.BuildingAge;
        existing.Floor = listing.Floor;
        existing.TotalFloors = listing.TotalFloors;
        existing.BathroomCount = listing.BathroomCount;
        existing.HeatingType = listing.HeatingType;
        existing.Furnished = listing.Furnished;
        existing.Balcony = listing.Balcony;
        existing.Elevator = listing.Elevator;
        existing.Parking = listing.Parking;
        existing.InSite = listing.InSite;
        existing.HasPool = listing.HasPool;
        existing.MonthlyPrice = listing.MonthlyPrice;
        existing.Deposit = listing.Deposit;
        existing.Dues = listing.Dues;
        existing.ImageUrl = listing.ImageUrl;
        existing.ImageGalleryJson = string.IsNullOrWhiteSpace(listing.ImageGalleryJson) ? "[]" : listing.ImageGalleryJson;
        existing.IsAdminRecommended = listing.IsAdminRecommended;
        _db.SaveChanges();
    }

    private static string NormalizeListingPurpose(string? value)
    {
        var raw = (value ?? string.Empty).Trim();
        if (raw.Length == 0)
        {
            return "Kiralık";
        }

        var normalized = raw
            .ToLowerInvariant()
            .Replace('ı', 'i')
            .Replace('ş', 's')
            .Replace('ğ', 'g')
            .Replace('ü', 'u')
            .Replace('ö', 'o')
            .Replace('ç', 'c');

        return normalized.StartsWith("sat", StringComparison.Ordinal)
            ? "Satılık"
            : "Kiralık";
    }

    public List<string> GetListingImageGallery(Listing listing)
    {
        var images = new List<string>();

        if (!string.IsNullOrWhiteSpace(listing.ImageGalleryJson))
        {
            try
            {
                var parsed = JsonSerializer.Deserialize<List<string>>(listing.ImageGalleryJson) ?? new List<string>();
                images.AddRange(parsed.Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()));
            }
            catch
            {
                // Ignore invalid legacy JSON.
            }
        }

        if (!string.IsNullOrWhiteSpace(listing.ImageUrl))
        {
            images.Insert(0, listing.ImageUrl.Trim());
        }

        return images
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    public string BuildGalleryJson(IEnumerable<string> imagePaths)
    {
        var list = imagePaths
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
        return JsonSerializer.Serialize(list);
    }

    public bool ToggleAdminRecommendation(int listingId)
    {
        var listing = GetListing(listingId) ?? throw new InvalidOperationException("İlan bulunamadı.");
        listing.IsAdminRecommended = !listing.IsAdminRecommended;
        _db.SaveChanges();
        return listing.IsAdminRecommended;
    }

    public bool ToggleDailyRecommendation(int listingId, int maxCount = 4)
    {
        var listing = GetListing(listingId) ?? throw new InvalidOperationException("İlan bulunamadı.");
        if (listing.IsDailyRecommended)
        {
            listing.IsDailyRecommended = false;
            _db.SaveChanges();
            return false;
        }

        var selectedCount = _db.Listings.Count(x => x.IsDailyRecommended);
        if (selectedCount >= maxCount)
        {
            throw new InvalidOperationException($"Günün tavsiye edilen evleri en fazla {maxCount} ilan olabilir.");
        }

        listing.IsDailyRecommended = true;
        _db.SaveChanges();
        return true;
    }

    public void DeleteListing(int id)
    {
        var listing = GetListing(id);
        if (listing is null) return;

        var comments = _db.Comments.Where(c => c.ListingId == id).ToList();
        var rentals = _db.Rentals.Where(r => r.ListingId == id).ToList();
        var offers = _db.Offers.Where(o => o.ListingId == id).ToList();
        var ratings = _db.Ratings.Where(r => r.ListingId == id).ToList();

        _db.Comments.RemoveRange(comments);
        _db.Rentals.RemoveRange(rentals);
        _db.Offers.RemoveRange(offers);
        _db.Ratings.RemoveRange(ratings);
        _db.Listings.Remove(listing);
        _db.SaveChanges();
    }

    public Comment AddComment(int listingId, string author, string content)
    {
        var comment = new Comment
        {
            ListingId = listingId,
            AuthorName = author,
            Content = content,
            CreatedAt = DateTime.UtcNow
        };
        _db.Comments.Add(comment);
        _db.SaveChanges();
        return comment;
    }

    public void DeleteComment(int commentId)
    {
        var comment = _db.Comments.FirstOrDefault(c => c.Id == commentId);
        if (comment is null) return;
        _db.Comments.Remove(comment);
        _db.SaveChanges();
    }

    public Rental Rent(int listingId, int renterId, string cardLast4, int? approvedOfferId = null)
    {
        var listing = GetListing(listingId) ?? throw new InvalidOperationException("İlan bulunamadı.");

        if (listing.OwnerUserId == renterId)
        {
            throw new InvalidOperationException("Satıcı kendi ilanini kiralayamaz.");
        }

        if (listing.IsRented)
        {
            throw new InvalidOperationException("Bu ilan zaten kiralandi.");
        }

        var rental = new Rental
        {
            ListingId = listingId,
            RenterUserId = renterId,
            ApprovedOfferId = approvedOfferId,
            PaymentCardLast4 = cardLast4,
            RentedAt = DateTime.UtcNow
        };

        listing.IsRented = true;
        listing.RentedAt = rental.RentedAt;
        _db.Rentals.Add(rental);
        _db.SaveChanges();
        return rental;
    }

    public Offer CreateOffer(int listingId, int fromUserId, decimal amount, string note)
    {
        var listing = GetListing(listingId) ?? throw new InvalidOperationException("İlan bulunamadı.");

        if (listing.OwnerUserId == fromUserId)
        {
            throw new InvalidOperationException("Kendi ilaniniza teklif veremezsiniz.");
        }

        if (listing.IsRented)
        {
            throw new InvalidOperationException("Kiralanmis ilana teklif verilemez.");
        }

        if (amount <= 0)
        {
            throw new InvalidOperationException("Teklif tutari 0'dan buyuk olmalidir.");
        }

        var offer = new Offer
        {
            ListingId = listingId,
            FromUserId = fromUserId,
            ToOwnerUserId = listing.OwnerUserId,
            Amount = amount,
            Note = note,
            Type = OfferType.PriceOffer,
            Status = OfferStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        _db.Offers.Add(offer);
        _db.SaveChanges();
        return offer;
    }

    public Offer CreateRentalRequest(int listingId, int fromUserId, string cardLast4)
    {
        var listing = GetListing(listingId) ?? throw new InvalidOperationException("İlan bulunamadı.");

        if (listing.OwnerUserId == fromUserId)
        {
            throw new InvalidOperationException("Satıcı kendi ilanini kiralayamaz.");
        }

        if (listing.IsRented)
        {
            throw new InvalidOperationException("Bu ilan zaten kiralandi.");
        }

        var hasPending = _db.Offers.Any(o =>
            o.ListingId == listingId &&
            o.FromUserId == fromUserId &&
            o.Type == OfferType.RentalRequest &&
            o.Status == OfferStatus.Pending);

        if (hasPending)
        {
            throw new InvalidOperationException("Bu ilan icin zaten bekleyen kiralama talebiniz var.");
        }

        var offer = new Offer
        {
            ListingId = listingId,
            FromUserId = fromUserId,
            ToOwnerUserId = listing.OwnerUserId,
            Amount = listing.MonthlyPrice,
            Note = "Kiralama talebi",
            Type = OfferType.RentalRequest,
            PaymentCardLast4 = cardLast4,
            Status = OfferStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        _db.Offers.Add(offer);
        _db.SaveChanges();
        return offer;
    }

    public List<OfferDisplayViewModel> GetOffersForListing(int listingId)
    {
        var listing = GetListing(listingId);
        if (listing is null) return new List<OfferDisplayViewModel>();

        return _db.Offers
            .Where(o => o.ListingId == listingId)
            .OrderByDescending(o => o.CreatedAt)
            .Select(o => new OfferDisplayViewModel
            {
                OfferId = o.Id,
                ListingId = o.ListingId,
                ListingTitle = listing.Title,
                FromUserName = _db.Users.Where(u => u.Id == o.FromUserId).Select(u => u.FullName).FirstOrDefault() ?? "Bilinmeyen",
                Amount = o.Amount,
                Note = o.Note,
                Type = o.Type,
                Status = o.Status,
                CreatedAt = o.CreatedAt
            })
            .ToList();
    }

    public List<OfferDisplayViewModel> GetIncomingOffers(int ownerUserId)
    {
        return _db.Offers
            .Where(o => o.ToOwnerUserId == ownerUserId)
            .OrderByDescending(o => o.CreatedAt)
            .Select(o => new OfferDisplayViewModel
            {
                OfferId = o.Id,
                ListingId = o.ListingId,
                ListingTitle = _db.Listings.Where(l => l.Id == o.ListingId).Select(l => l.Title).FirstOrDefault() ?? "İlan",
                FromUserName = _db.Users.Where(u => u.Id == o.FromUserId).Select(u => u.FullName).FirstOrDefault() ?? "Bilinmeyen",
                Amount = o.Amount,
                Note = o.Note,
                Type = o.Type,
                Status = o.Status,
                CreatedAt = o.CreatedAt
            })
            .ToList();
    }

    public Offer UpdateOfferStatus(int ownerUserId, int offerId, OfferStatus status)
    {
        var offer = _db.Offers.FirstOrDefault(o => o.Id == offerId);
        if (offer is null) throw new InvalidOperationException("Teklif bulunamadi.");
        if (offer.ToOwnerUserId != ownerUserId) throw new InvalidOperationException("Bu teklifi yonetme yetkiniz yok.");
        if (offer.Status != OfferStatus.Pending) return offer;

        offer.Status = status;

        if (status == OfferStatus.Accepted && offer.Type == OfferType.RentalRequest)
        {
            Rent(offer.ListingId, offer.FromUserId, offer.PaymentCardLast4, offer.Id);

            var others = _db.Offers.Where(x =>
                x.ListingId == offer.ListingId &&
                x.Id != offer.Id &&
                x.Status == OfferStatus.Pending).ToList();

            foreach (var pending in others)
            {
                pending.Status = OfferStatus.Rejected;
            }
        }

        _db.SaveChanges();
        return offer;
    }

    public OfferMessageActionViewModel? GetOfferMessageAction(int currentUserId, int? offerId)
    {
        if (!offerId.HasValue)
        {
            return null;
        }

        var offer = _db.Offers.FirstOrDefault(o => o.Id == offerId.Value);
        if (offer is null)
        {
            return null;
        }

        var listing = _db.Listings.FirstOrDefault(l => l.Id == offer.ListingId);
        if (listing is null)
        {
            return null;
        }

        return new OfferMessageActionViewModel
        {
            OfferId = offer.Id,
            ListingId = listing.Id,
            ListingTitle = listing.Title,
            Amount = offer.Amount,
            OfferType = offer.Type,
            OfferStatus = offer.Status,
            CanRespond = offer.ToOwnerUserId == currentUserId && offer.Status == OfferStatus.Pending,
            StatusLabel = offer.Type == OfferType.RentalRequest && offer.Status == OfferStatus.Accepted
                ? "Kiralandi"
                : offer.Status switch
                {
                    OfferStatus.Accepted => "Kabul Edildi",
                    OfferStatus.Rejected => "Reddedildi",
                    _ => "Beklemede"
                }
        };
    }

    public Dictionary<int, OfferMessageActionViewModel> GetOfferMessageActionsForConversation(IEnumerable<Message> messages, int currentUserId)
    {
        var offerIds = messages
            .Where(m => m.OfferId.HasValue)
            .Select(m => m.OfferId!.Value)
            .Distinct()
            .ToList();

        if (offerIds.Count == 0)
        {
            return new Dictionary<int, OfferMessageActionViewModel>();
        }

        var offers = _db.Offers
            .Where(o => offerIds.Contains(o.Id))
            .ToList();

        if (offers.Count == 0)
        {
            return new Dictionary<int, OfferMessageActionViewModel>();
        }

        var listingIds = offers.Select(o => o.ListingId).Distinct().ToList();
        var listings = _db.Listings
            .Where(l => listingIds.Contains(l.Id))
            .ToDictionary(l => l.Id, l => l);

        var actionByOfferId = offers.ToDictionary(
            o => o.Id,
            o =>
            {
                var listing = listings.TryGetValue(o.ListingId, out var found) ? found : null;
                return new OfferMessageActionViewModel
                {
                    OfferId = o.Id,
                    ListingId = o.ListingId,
                    ListingTitle = listing?.Title ?? "İlan",
                    Amount = o.Amount,
                    OfferType = o.Type,
                    OfferStatus = o.Status,
                    CanRespond = o.ToOwnerUserId == currentUserId && o.Status == OfferStatus.Pending,
                    StatusLabel = o.Type == OfferType.RentalRequest && o.Status == OfferStatus.Accepted
                        ? "Kiralandi"
                        : o.Status switch
                        {
                            OfferStatus.Accepted => "Kabul Edildi",
                            OfferStatus.Rejected => "Reddedildi",
                            _ => "Beklemede"
                        }
                };
            });

        var result = new Dictionary<int, OfferMessageActionViewModel>();
        foreach (var msg in messages)
        {
            if (!msg.OfferId.HasValue)
            {
                continue;
            }

            if (actionByOfferId.TryGetValue(msg.OfferId.Value, out var action))
            {
                result[msg.Id] = action;
            }
        }

        return result;
    }

    public Offer RespondToOfferFromMessage(int currentUserId, int offerId, OfferStatus status)
    {
        if (status != OfferStatus.Accepted && status != OfferStatus.Rejected)
        {
            throw new InvalidOperationException("Teklif cevabi yalnizca kabul veya red olabilir.");
        }

        return UpdateOfferStatus(currentUserId, offerId, status);
    }

    public bool HasUserRentedListing(int listingId, int userId)
        => _db.Rentals.Any(x => x.ListingId == listingId && x.RenterUserId == userId);

    public bool CanUserRateListing(int listingId, int userId)
    {
        var listing = GetListing(listingId);
        if (listing is null) return false;
        if (listing.OwnerUserId == userId) return false;
        return HasUserRentedListing(listingId, userId);
    }

    public Rating? GetUserRating(int listingId, int userId)
        => _db.Ratings.FirstOrDefault(x => x.ListingId == listingId && x.RenterUserId == userId);

    public void UpsertRating(int listingId, int renterUserId, int listingScore, int sellerScore, string comment)
    {
        var listing = GetListing(listingId) ?? throw new InvalidOperationException("İlan bulunamadı.");
        if (!CanUserRateListing(listingId, renterUserId))
        {
            throw new InvalidOperationException("Puanlama icin ilani kiralamis olmaniz gerekir.");
        }

        if (listingScore is < 1 or > 5 || sellerScore is < 1 or > 5)
        {
            throw new InvalidOperationException("Puanlar 1 ile 5 arasinda olmalidir.");
        }

        var existing = GetUserRating(listingId, renterUserId);
        if (existing is null)
        {
            existing = new Rating
            {
                ListingId = listingId,
                SellerUserId = listing.OwnerUserId,
                RenterUserId = renterUserId,
                ListingScore = listingScore,
                SellerScore = sellerScore,
                Comment = (comment ?? string.Empty).Trim(),
                CreatedAt = DateTime.UtcNow
            };
            _db.Ratings.Add(existing);
        }
        else
        {
            existing.ListingScore = listingScore;
            existing.SellerScore = sellerScore;
            existing.Comment = (comment ?? string.Empty).Trim();
            existing.CreatedAt = DateTime.UtcNow;
        }

        _db.SaveChanges();
    }

    public (double average, int count) GetListingRatingSummary(int listingId)
    {
        var list = _db.Ratings.Where(x => x.ListingId == listingId).ToList();
        if (list.Count == 0) return (0, 0);
        return (Math.Round(list.Average(x => x.ListingScore), 1), list.Count);
    }

    public (double average, int count) GetSellerRatingSummary(int sellerUserId)
    {
        var list = _db.Ratings.Where(x => x.SellerUserId == sellerUserId).ToList();
        if (list.Count == 0) return (0, 0);
        return (Math.Round(list.Average(x => x.SellerScore), 1), list.Count);
    }

    public List<RatingDisplayViewModel> GetRatingsForListing(int listingId)
    {
        return _db.Ratings
            .Where(x => x.ListingId == listingId)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new RatingDisplayViewModel
            {
                RenterName = _db.Users.Where(u => u.Id == x.RenterUserId).Select(u => u.FullName).FirstOrDefault() ?? "Kullanici",
                ListingScore = x.ListingScore,
                SellerScore = x.SellerScore,
                Comment = x.Comment,
                CreatedAt = x.CreatedAt
            })
            .ToList();
    }

    public SellerDashboardViewModel GetSellerDashboard(int ownerUserId)
    {
        var myListings = GetListingsByOwner(ownerUserId);
        var incomingOffers = GetIncomingOffers(ownerUserId);

        var total = myListings.Count;
        var rented = myListings.Count(x => x.IsRented);
        var pending = incomingOffers.Count(x => x.Status == OfferStatus.Pending);
        var rate = total == 0 ? 0 : Math.Round((decimal)rented / total * 100m, 1);

        return new SellerDashboardViewModel
        {
            TotalListings = total,
            RentedListings = rented,
            PendingOffers = pending,
            ConversionRate = rate,
            MyListings = myListings,
            IncomingOffers = incomingOffers
        };
    }

    public List<InboxConversationItemViewModel> GetInboxConversations(int currentUserId)
    {
        var messages = _db.Messages
            .Where(m => m.FromUserId == currentUserId || m.ToUserId == currentUserId)
            .ToList();

        var grouped = messages
            .GroupBy(m => m.FromUserId == currentUserId ? m.ToUserId : m.FromUserId)
            .Select(g =>
            {
                var partner = _db.Users.FirstOrDefault(u => u.Id == g.Key);
                if (partner is null)
                {
                    return null;
                }

                var last = g.OrderByDescending(x => x.CreatedAt).First();
                var lastPreview = last.IsDeleted
                    ? "Bu mesaj silindi."
                    : (!string.IsNullOrWhiteSpace(last.Content)
                        ? last.Content
                        : (!string.IsNullOrWhiteSpace(last.ImageUrl) ? "[Gorsel]" : ""));
                return new InboxConversationItemViewModel
                {
                    PartnerUserId = partner.Id,
                    PartnerName = partner.FullName,
                    PartnerRole = partner.Role,
                    LastMessage = lastPreview,
                    LastMessageAt = last.CreatedAt,
                    LastFromMe = last.FromUserId == currentUserId,
                    UnreadCount = g.Count(x => x.ToUserId == currentUserId && !x.IsRead)
                };
            })
            .Where(x => x is not null)
            .Cast<InboxConversationItemViewModel>()
            .OrderByDescending(x => x.LastMessageAt)
            .ToList();

        return grouped;
    }

    public List<Message> GetConversation(int userA, int userB)
    {
        return _db.Messages
            .Where(m => (m.FromUserId == userA && m.ToUserId == userB) || (m.FromUserId == userB && m.ToUserId == userA))
            .OrderBy(m => m.CreatedAt)
            .ToList();
    }

    public int GetUnreadCount(int currentUserId)
        => _db.Messages.Count(m => m.ToUserId == currentUserId && !m.IsRead);

    public Message? GetLatestUnreadMessage(int currentUserId)
        => _db.Messages
            .Where(m => m.ToUserId == currentUserId && !m.IsRead)
            .OrderByDescending(m => m.CreatedAt)
            .FirstOrDefault();

    public void MarkConversationAsRead(int currentUserId, int withUserId)
    {
        var list = _db.Messages.Where(m => m.FromUserId == withUserId && m.ToUserId == currentUserId && !m.IsRead).ToList();
        foreach (var m in list)
        {
            m.IsRead = true;
        }

        _db.SaveChanges();
    }

    public Message SendMessage(int fromUserId, int toUserId, string content, string? imageUrl = null, int? offerId = null)
    {
        var message = new Message
        {
            FromUserId = fromUserId,
            ToUserId = toUserId,
            Content = content.Trim(),
            ImageUrl = imageUrl?.Trim() ?? string.Empty,
            OfferId = offerId,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };
        _db.Messages.Add(message);
        _db.SaveChanges();
        return message;
    }

    public void EditMessage(int messageId, int currentUserId, string newContent)
    {
        var message = _db.Messages.FirstOrDefault(m => m.Id == messageId)
            ?? throw new InvalidOperationException("Mesaj bulunamadi.");

        if (message.FromUserId != currentUserId)
        {
            throw new InvalidOperationException("Bu mesaji duzenleme yetkiniz yok.");
        }

        if (message.IsDeleted)
        {
            throw new InvalidOperationException("Silinmis mesaj duzenlenemez.");
        }

        var nextContent = (newContent ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(nextContent))
        {
            throw new InvalidOperationException("Mesaj bos birakilamaz.");
        }

        message.Content = nextContent;
        message.IsEdited = true;
        message.EditedAt = DateTime.UtcNow;
        _db.SaveChanges();
    }

    public void DeleteMessage(int messageId, int currentUserId)
    {
        var message = _db.Messages.FirstOrDefault(m => m.Id == messageId)
            ?? throw new InvalidOperationException("Mesaj bulunamadi.");

        if (message.FromUserId != currentUserId)
        {
            throw new InvalidOperationException("Bu mesaji silme yetkiniz yok.");
        }

        message.IsDeleted = true;
        message.Content = string.Empty;
        message.ImageUrl = string.Empty;
        message.IsEdited = false;
        message.EditedAt = DateTime.UtcNow;
        _db.SaveChanges();
    }
}
