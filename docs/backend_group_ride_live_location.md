# Backend Rehberi — Grup Sürüşünde Canlı Konum Paylaşımı + Ortak Rota

> Hedef: Aynı grup sürüşündeki (GroupRide) kullanıcılar haritada **birbirini canlı görsün**, ve sürüşü oluşturan kişinin **rotası otomatik olarak tüm üyelere** gelsin. Konum paylaşımı **opt-in** (üye isterse paylaşır).

Bu doküman backend ekibi içindir. Mobil tarafta altyapının önemli bir kısmı zaten hazır; aşağıda "MEVCUT" ve "YAPILACAK" olarak ayrılmıştır.

---

## 0. Mevcut Durum (mobil zaten bunları kullanıyor)

| Katman | Var olan |
|---|---|
| REST | `POST/GET/PUT/DELETE /api/GroupRide`, `GET /api/GroupRide/{id}`, `POST /api/GroupRide/{id}/sos` |
| Hub (callhub) invoke | `JoinRideGroup(rideId)`, `LeaveRideGroup(rideId)` |
| Hub (callhub) event | `RideCreated`, `ReceiveRideLocationUpdate(userId, data)`, `RideTerminated`, `GroupRideUpdated`, `ReceiveSosAlert` |

Yani client `JoinRideGroup` ile gruba katılıyor ve `ReceiveRideLocationUpdate` event'ini **dinlemeye hazır**. Eksik olan: bunu besleyen **gönderme** metodu, **rota** alanı ve **opt-in** mantığı.

---

## 1. Veri Modeli Değişiklikleri

### 1.1. GroupRide tablosu — rota alanları (YENİ)

Kuranın çizdiği rotanın üyelere gitmesi için rotanın saklanması gerekir. Önerilen alanlar:

```
GroupRide
  ...mevcut alanlar...
  + RouteGeometry        nvarchar(max)   NULL   -- Encoded polyline (Mapbox polyline6) VEYA GeoJSON LineString
  + RouteProfile         nvarchar(32)    NULL   -- "driving" | "driving-traffic" vb.
  + RouteDistanceMeters  float           NULL
  + RouteDurationSeconds int             NULL
  + RouteWaypointsJson   nvarchar(max)   NULL   -- [{lat,lng,name}] sıralı waypoint listesi (yeniden hesap için)
  + RouteUpdatedAt       datetime2       NULL
```

> **Format önerisi:** Mobil Mapbox kullanıyor. En verimlisi **encoded polyline (precision 6)** string'i saklamak — küçük, hazır çizilebilir. Alternatif GeoJSON LineString de olur ama daha büyük payload. İkisinden birini seçip sözleşmeye yazın (aşağıda `polyline6` varsayıldı).

### 1.2. GroupRideParticipant tablosu (YENİ veya mevcut tabloya alan)

Katılımcı + opt-in konum paylaşımı + son bilinen konum:

```
GroupRideParticipant
  Id                bigint PK
  GroupRideId       int FK -> GroupRide
  UserId            int FK -> User
  JoinedAt          datetime2
  LeftAt            datetime2       NULL
  ShareLocation     bit             NOT NULL DEFAULT 1   -- opt-in toggle
  LastLat           float           NULL
  LastLng           float           NULL
  LastHeading       float           NULL                 -- derece, 0-360 (kuzey=0)
  LastSpeedKmh      float           NULL
  LastLocationAt    datetime2       NULL
  UNIQUE(GroupRideId, UserId)
```

> Son konumu DB'de tutmak şart değil ama **yeni katılan üyenin diğerlerini hemen görebilmesi** (join snapshot) ve **kısa kopukluk sonrası geri gelince state** için çok faydalı. Yüksek frekanslı yazımdan kaçınmak için son konumu in-memory cache (ör. Redis) + periyodik DB flush ile tutmak ideal. MVP'de doğrudan DB update de kabul edilebilir (throttle ile, bkz. §4).

---

## 2. REST Endpoint Değişiklikleri

### 2.1. GroupRide create/update — rota ekleme

`POST /api/GroupRide` ve `PUT /api/GroupRide/{id}` body'sine rota alanları eklenebilir (opsiyonel):

```jsonc
{
  // ...mevcut create alanları...
  "routeGeometry": "ki~kH..._encoded_polyline6_...",
  "routeProfile": "driving",
  "routeDistanceMeters": 47230,
  "routeDurationSeconds": 3120,
  "routeWaypoints": [
    { "lat": 40.99, "lng": 29.02, "name": "Kadıköy" },
    { "lat": 41.17, "lng": 29.60, "name": "Şile" }
  ]
}
```

> Mobil rotayı Mapbox Directions'tan zaten alıyor; kuran "Başlat"a basınca elindeki encoded polyline'ı buraya gönderecek. Backend sadece saklayıp yayınlayacak (rotayı backend'in yeniden hesaplamasına gerek yok — ama isterseniz waypoints'ten doğrulama yapabilirsiniz).

### 2.2. `GET /api/GroupRide/{id}` yanıtına ekleme

Detay yanıtına şunlar eklenmeli ki, mobil sürüşe girince ortak rotayı ve aktif üyeleri tek seferde çekebilsin:

```jsonc
{
  "data": {
    // ...mevcut alanlar...
    "routeGeometry": "...polyline6...",
    "routeProfile": "driving",
    "routeDistanceMeters": 47230,
    "routeDurationSeconds": 3120,
    "participants": [
      {
        "userId": 12,
        "fullName": "Ahmet Y.",
        "username": "ahmety",
        "profilePictureUrl": "https://...",
        "shareLocation": true,
        "lastLat": 40.99, "lastLng": 29.02,
        "lastHeading": 145.0, "lastSpeedKmh": 52.0,
        "lastLocationAt": "2026-06-06T10:32:11Z",
        "isOrganizer": false
      }
    ]
  }
}
```

### 2.3. (Opsiyonel) Konum paylaşımı toggle endpoint

```
PUT /api/GroupRide/{id}/location-sharing
Body: { "shareLocation": true|false }
```

Üye konum paylaşımını açıp kapatabilsin. `false` ise backend bu üyenin konumunu **yaymaz** ve `participants` snapshot'ında `lastLat/lastLng = null` döner. (Toggle'ı SignalR invoke olarak da yapabilirsiniz, bkz. §3.4.)

---

## 3. SignalR Hub Metotları (callhub) — ÇEKİRDEK

Hepsi `callhub` içine eklenecek (mobil zaten oraya bağlı). SignalR group adı konvansiyonu mevcut `JoinRideGroup` ile aynı: **grup adı = `ride_{rideId}`** (mevcut implementasyonda hangi isim kullanılıyorsa onu koruyun; mobil sadece `rideId` gönderiyor, grup adını backend belirliyor).

### 3.1. `JoinRideGroup(string rideId)` — MEVCUT, genişletilecek

Şu an muhtemelen sadece connection'ı SignalR group'una ekliyor. Eklenecekler:

1. Çağıranın `GroupRideParticipant` kaydını upsert et (yoksa oluştur, `LeftAt = null`).
2. **Join snapshot'ı SADECE çağırana gönder** — ortak rota + o an paylaşan diğer üyelerin son konumları:

```csharp
await Clients.Caller.SendAsync("RideJoinSnapshot", new {
    rideId = id,
    route = new {
        geometry = ride.RouteGeometry,
        profile  = ride.RouteProfile,
        distanceMeters = ride.RouteDistanceMeters,
        durationSeconds = ride.RouteDurationSeconds
    },
    participants = activeParticipants.Select(p => new {
        userId = p.UserId,
        fullName = p.User.FullName,
        username = p.User.Username,
        profilePictureUrl = p.User.ProfilePictureUrl,
        shareLocation = p.ShareLocation,
        lat = p.ShareLocation ? p.LastLat : (double?)null,
        lng = p.ShareLocation ? p.LastLng : (double?)null,
        heading = p.LastHeading,
        speedKmh = p.LastSpeedKmh,
        lastLocationAt = p.LastLocationAt
    })
});
```

3. Diğer üyelere "biri katıldı" bildir (opsiyonel ama UI için iyi):

```csharp
await Clients.OthersInGroup(groupName).SendAsync("RideParticipantJoined", new {
    rideId = id, userId, fullName, username, profilePictureUrl
});
```

> **Not:** `RideJoinSnapshot` ve `RideParticipantJoined` mobilde henüz dinlenmiyor — bunlar yeni event'ler, mobil tarafı sonra eklenecek. Sözleşmeyi şimdi sabitlemek önemli.

### 3.2. `UpdateRideLocation(...)` — YENİ (en kritik eksik)

Client kendi konumunu buraya basacak; backend gruba yayacak.

```csharp
public async Task UpdateRideLocation(
    string rideId, double lat, double lng, double? heading, double? speedKmh)
{
    var userId = /* JWT'den */;
    var id = int.Parse(rideId);

    // 1) Yetki: kullanıcı bu sürüşün aktif katılımcısı mı?
    var participant = await _db.Participants
        .FirstOrDefaultAsync(p => p.GroupRideId == id && p.UserId == userId && p.LeftAt == null);
    if (participant == null) return;                 // gruba ait değil → yok say
    if (!participant.ShareLocation) return;          // opt-out → yayma

    // 2) Throttle (bkz. §4) — çok sık gelirse at
    // 3) Son konumu güncelle (cache/DB)
    participant.LastLat = lat; participant.LastLng = lng;
    participant.LastHeading = heading; participant.LastSpeedKmh = speedKmh;
    participant.LastLocationAt = DateTime.UtcNow;

    // 4) Gruptaki DİĞERLERİNE yay — mobil zaten bu event'i dinliyor!
    await Clients.OthersInGroup(groupName).SendAsync("ReceiveRideLocationUpdate",
        userId.ToString(),
        new {
            lat, lng, heading, speedKmh,
            timestamp = DateTime.UtcNow
        });
}
```

> **Sözleşme kritik:** Mobil `ReceiveRideLocationUpdate`'i `arguments[0] = userId (string)`, `arguments[1] = { ... }` (Map) olarak parse ediyor. Yani **ilk parametre userId string, ikinci parametre konum objesi** olmalı. İçindeki anahtarlar (`lat`, `lng`, `heading`, `speedKmh`, `timestamp`) mobil tarafça okunacağı için bu isimleri sabitleyelim.

### 3.3. `SetRideRoute(...)` veya REST üzerinden rota yayınlama — YENİ

Kuran rotayı belirleyince/güncelleyince tüm gruba bildirilmeli. İki seçenek:

**Seçenek A (önerilen):** Rota REST ile kaydedilir (`PUT /api/GroupRide/{id}`), kayıttan sonra backend gruba broadcast eder:

```csharp
await _hub.Clients.Group(groupName).SendAsync("RideRouteUpdated", new {
    rideId = id,
    geometry = ride.RouteGeometry,
    profile = ride.RouteProfile,
    distanceMeters = ride.RouteDistanceMeters,
    durationSeconds = ride.RouteDurationSeconds
});
```

**Seçenek B:** Hub metodu `SetRideRoute(rideId, geometry, ...)` — sadece organizatör çağırabilir, DB'ye yazar + yukarıdaki `RideRouteUpdated`'ı yayar.

> **Yetki:** Rotayı yalnızca `GroupRide.OrganizerId == userId` (kuran) değiştirebilir. Başka üye denerse 403 / yok say.
> `RideRouteUpdated` mobilde yeni event olacak (sonra eklenecek). Üye bu event'i alınca haritasına rotayı çizecek.

### 3.4. `SetRideLocationSharing(string rideId, bool share)` — YENİ (opsiyonel)

REST §2.3 yerine hub'dan da yapılabilir. `share=false` → konumu yaymayı durdur + diğerlerine `RideParticipantLocationStopped(userId)` bildir ki haritadan marker'ı kaldırsınlar.

### 3.5. `LeaveRideGroup` — MEVCUT, genişletilecek

`LeftAt = now` yaz + diğerlerine bildir:

```csharp
await Clients.OthersInGroup(groupName).SendAsync("RideParticipantLeft", new {
    rideId = id, userId
});
```

### 3.6. Bağlantı kopması (OnDisconnectedAsync)

Üyenin connection'ı düşerse (uygulama kapandı/şebeke gitti) son konumda donmasın. `OnDisconnectedAsync`'te kullanıcının aktif olduğu ride gruplarına `RideParticipantLeft` (veya `RideParticipantStale`) yayınla. `LeftAt`'ı hemen yazmak yerine "stale" işaretleyip kısa bir grace period (ör. 30 sn) sonra düşürmek reconnect senaryosunda daha iyi (mobil zaten otomatik reconnect yapıyor).

---

## 4. Performans, Throttling, Ölçek

Konum paylaşımı yüksek frekanslı olduğu için en kritik konu budur.

- **Client gönderim hızı:** Mobil ~3-5 saniyede bir (veya 25-50 m hareketde bir) gönderecek şekilde ayarlanacak (mobil tarafı). Backend yine de korumalı olmalı.
- **Server-side throttle:** Aynı kullanıcıdan gelen güncellemeler için minimum aralık uygula (ör. < 1 sn ise at). Connection bazlı son-timestamp cache yeterli.
- **DB yazımı:** Her güncellemede DB'ye yazma — **in-memory/Redis** son konum tut, DB'ye 10-15 sn'de bir veya leave/disconnect'te flush et. MVP'de doğrudan DB update kabul ama throttle şart.
- **Fan-out:** `Clients.OthersInGroup` kullan (kendine geri yollama). Grup başına üye sayısı genelde küçük (<50), sorun olmaz.
- **Backplane:** Birden çok sunucu instance'ı varsa SignalR **Redis backplane** zaten kurulu olmalı (mevcut call/voice feature için muhtemelen var — doğrulayın). Group broadcast'leri instance'lar arası çalışsın diye gerekli.
- **Payload küçük tut:** Konum objesinde gereksiz alan olmasın (lat,lng,heading,speed,ts yeter).

---

## 5. Yetki ve Gizlilik Kuralları (özet)

1. `UpdateRideLocation` / `JoinRideGroup`: yalnızca o sürüşün **aktif katılımcısı**. Değilse yok say.
2. Konum yayını yalnızca `ShareLocation == true` olan üye için.
3. `isPrivate == true` sürüşlerde join öncesi davet/üyelik kontrolü (mevcut GroupRide mantığına uyumlu).
4. Rota değiştirme: yalnızca **organizatör**.
5. Snapshot'ta opt-out üyenin konum alanları `null` dönsün.
6. SOS (`ReceiveSosAlert`) zaten var — konum paylaşımı kapalı olsa bile SOS konumu gider (acil durum istisnası).

---

## 6. Event/Metot Sözleşmesi — Tam Liste (mobil ile anlaşılan isimler)

### Client → Server (invoke)
| Metot | Parametre | Durum |
|---|---|---|
| `JoinRideGroup` | `rideId: string` | MEVCUT — snapshot dönecek şekilde genişlet (§3.1) |
| `LeaveRideGroup` | `rideId: string` | MEVCUT — genişlet (§3.5) |
| `UpdateRideLocation` | `rideId: string, lat: double, lng: double, heading: double?, speedKmh: double?` | **YENİ** (§3.2) |
| `SetRideLocationSharing` | `rideId: string, share: bool` | YENİ, opsiyonel (§3.4) |
| `SetRideRoute` | `rideId, geometry, profile, distanceMeters, durationSeconds` | YENİ, opsiyonel — REST de olur (§3.3) |

### Server → Client (event)
| Event | Payload | Durum |
|---|---|---|
| `ReceiveRideLocationUpdate` | `userId: string`, `{ lat, lng, heading, speedKmh, timestamp }` | **MEVCUT** (mobil dinliyor) — `UpdateRideLocation` bunu beslemeli |
| `RideJoinSnapshot` | `{ rideId, route{...}, participants[...] }` | YENİ (§3.1) |
| `RideRouteUpdated` | `{ rideId, geometry, profile, distanceMeters, durationSeconds }` | YENİ (§3.3) |
| `RideParticipantJoined` | `{ rideId, userId, fullName, username, profilePictureUrl }` | YENİ (§3.1) |
| `RideParticipantLeft` | `{ rideId, userId }` | YENİ (§3.5/3.6) |
| `RideParticipantLocationStopped` | `{ rideId, userId }` | YENİ, opsiyonel (§3.4) |
| `RideCreated` / `GroupRideUpdated` / `RideTerminated` | mevcut payload | MEVCUT |

---

## 7. Önerilen Uygulama Sırası (backend)

1. **DB migration**: GroupRide rota alanları + GroupRideParticipant tablosu (§1).
2. **`GET /api/GroupRide/{id}`** yanıtına route + participants ekle (§2.2). — Mobil önce snapshot'ı REST'ten de çekebilir.
3. **`UpdateRideLocation` hub metodu** + `ReceiveRideLocationUpdate` yayını (§3.2). — Asıl canlı konum burada başlar.
4. **`JoinRideGroup` snapshot genişletmesi** (§3.1).
5. **Rota yayını** (`RideRouteUpdated`, §3.3) + create/update body rota alanları (§2.1).
6. **Opt-in toggle** (§2.3 / §3.4) + leave/disconnect event'leri (§3.5/3.6).
7. **Throttle + Redis backplane doğrulama** (§4).

> Adım 1-3 tamamlanınca "üyeler birbirini canlı görür" çalışır. Adım 4-5 "ortak rota otomatik gelir"i tamamlar. 6-7 cilalama/gizlilik/ölçek.

---

## 8. Mobil tarafında hazır olanlar (backend ekibinin bilmesi için)

- callhub bağlantısı, otomatik reconnect, `JoinRideGroup`/`LeaveRideGroup` invoke'ları **çalışıyor**.
- `ReceiveRideLocationUpdate` event'i parse edilip stream'e (`_rideLocationUpdateController`) düşüyor — yani backend yaymaya başladığı an mobil veriyi alır.
- Yeni event'ler (`RideJoinSnapshot`, `RideRouteUpdated`, `RideParticipant*`) mobilde **henüz dinlenmiyor**; bu rehber onaylandıktan sonra mobil tarafı eklenecek. Bu yüzden **isim ve payload sözleşmesini (§6) sabitlemek** kritik.
