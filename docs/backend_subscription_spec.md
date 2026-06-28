# Abonelik Sistemi — Backend Beklentileri (Mobil tarafı)

Bu doküman, helmove mobil uygulamasının abonelik/plan sisteminde backend'den
**ne beklediğini** anlatır. Ödeme akışı **RevenueCat + App Store / Google Play**
üzerindendir; backend **ödeme almaz**. Backend'in görevi: (1) plan kataloğu
metinlerini sağlamak (opsiyonel), (2) RevenueCat webhook'u ile kullanıcının
tier'ını güncel tutmak (zorunlu), (3) kullanıcı profilinde tier döndürmek (zorunlu).

---

## 0. Mimari özet (akış)

```
Kullanıcı satın alır
   └─> RevenueCat (App Store / Play faturalandırma)
          ├─> Mobil: entitlement'ları okur  → UI'yi açar (client-authoritative)
          └─> Webhook → BACKEND: user.tier güncelle  (server-authoritative)
Mobil her açılışta /me ile user.tier'ı da okur (gating + sunucu yetkilendirmesi)
```

- **RevenueCat App User ID = backend user id.** Mobil `Purchases.logIn(backendUserId)`
  çağırır. Yani webhook payload'ındaki `app_user_id` = sizin user id'niz.
- **Entitlement identifier'ları:** `pro` ve `plus` (RevenueCat dashboard'da bu
  isimlerle tanımlı). Pro > Plus önceliklidir.

---

## 1. (ZORUNLU) Kullanıcı profilinde `tier` / `tierIndex`

Mobil, kullanıcının mevcut planını profil/me yanıtından okur
(`AuthProvider.currentUser.tier`). Bu, şu ekranları etkiler:
- "Planını Seç" sayfasında **zaten aboneliği olana plan satışı gösterilmez**
  (yalnız Free kullanıcı planları görür).
- Tier'a bağlı özellik kilitleri.

**Beklenen alanlar (kullanıcı objesinde):**

| Alan | Tip | Değerler | Not |
|------|-----|----------|-----|
| `tier` | string | `"Free"` / `"Plus"` / `"Pro"` | Büyük/küçük harf duyarsız parse edilir |
| `tierIndex` | int | `0` / `1` / `2` | `tier` yoksa bundan türetilir |

> Mobil ikisinden birini kabul eder; ikisini de göndermek en güvenlisi.
> Ayrıca `premiumTier` alias'ı da parse edilir ama standart olarak `tier` kullanın.

---

## 2. (ZORUNLU) RevenueCat → Backend Webhook

Satın alma / yenileme / iptal / iade olduğunda RevenueCat backend'e webhook atar.
Backend bu webhook ile `user.tier` / `tierIndex`'i günceller:

- `app_user_id` → ilgili kullanıcı.
- Aktif entitlement `pro` varsa → `tier = "Pro"` (`tierIndex = 2`)
- Aktif entitlement `plus` varsa → `tier = "Plus"` (`tierIndex = 1`)
- Aktif entitlement yoksa (expire/iptal/iade) → `tier = "Free"` (`tierIndex = 0`)

> Mobil, RevenueCat'ten anlık olarak tier'ı zaten okuyabildiği için UI gating
> webhook olmadan da çalışır; **ancak sunucu tarafı yetkilendirme** (örn. grup
> sürüşü oluşturma limiti, premium API'leri) için backend'in tier'ı bilmesi şart.

---

## 3. (OPSİYONEL) Plan Kataloğu Endpoint'i

`GET /api/subscription/plans`

Plan kartlarındaki **ücretli planların** (Plus/Pro) başlık/açıklama/özellik/badge
metinlerini backend'den yönetmek için. Dönmezse mobil kendi varsayılan
metinlerini gösterir (uygulama çalışmaya devam eder).

### Yanıt formatı
Şunların herhangi biri kabul edilir:
```jsonc
// düz liste
[ { ...plan }, ... ]
// veya sarmalı
{ "data": [ { ...plan }, ... ] }   // "Data" da olur
```

### Plan objesi alanları
Mobil hem camelCase hem PascalCase okur (`price`/`Price` vb.).

| Alan | Tip | Zorunlu | Açıklama |
|------|-----|---------|----------|
| `id` | int | ✓ | Plan id |
| `name` | string | ✓ | Plan adı |
| `code` | string | ✓ | **RevenueCat product identifier ile birebir aynı olmalı** (aşağıdaki tabloya bak). Kartla eşleşme bunun üzerinden yapılır. |
| `price` | number | – | Bilgi amaçlı (kart fiyatı mağazadan gelir) |
| `currency` | string | – | Para birimi |
| `description` | string | – | Kısa açıklama |
| `fullDescription` | string | – | Uzun açıklama → kartta açıklama olarak kullanılır |
| `features` | string[] | – | **Kart madde listesi.** Doluysa mobil varsayılanını **ezer**. JSON-encoded string array da kabul (`featuresJson`). |
| `durationDays` | int | – | Süre |
| `isActive` | bool | – | Varsayılan `true` |
| `isRecommended` | bool | – | Önerilen plan |
| `tier` | string | – | `"Plus"`/`"Pro"` |
| `tierIndex` | int | – | `1`/`2` |
| `badge` | string? | – | Kart üstü rozet metni (örn. `"En Popüler"`) |

### ⚠️ Önemli kısıtlar
- **Free planın metinleri backend'den GELMEZ.** Free kartı mobilde sabit kuruluyor
  (`code = "free"` olan backend planı kartı beslemez). Free özellikleri mobilde
  güncellendi (artık "Reklamlı Deneyim" yazmıyor). Free metnini değiştirmek
  istersen mobilde `_fallbackFeatures(UserTier.free)` güncellenir.
- **Plus/Pro özelliklerini backend'den yönetmek istiyorsan**, her mağaza product
  id'si için (`code` = product id) bir plan döndür ve `features` doldur. Aksi
  halde mobil kendi varsayılan listesini gösterir.

### `code` ↔ RevenueCat product id eşleşmesi (zorunlu)
```
plus_monthly_1   → Plus Aylık
plus_monthly_6   → Plus 6 Aylık
plus_yearly_1    → Plus Yıllık
pro_monthly_1    → Pro Aylık
pro_monthly_6    → Pro 6 Aylık
pro_yearly_1     → Pro Yıllık
```

---

## 4. KULLANILMAYAN: `subscribe` endpoint'i

Mobildeki `subscribe(planId, paymentProvider, transactionId)` **kullanılmıyor** —
satın alma RevenueCat üzerinden yapılır. Backend'in ayrı bir satın alma/doğrulama
endpoint'i sağlamasına gerek yok; doğrulama RevenueCat ↔ store arasında.

---

## Özet checklist (backend developer)

- [ ] **/me (veya kullanıcı profili) yanıtına `tier` + `tierIndex` ekle.** (zorunlu)
- [ ] **RevenueCat webhook handler'ı kur**, `app_user_id`→user, entitlement
      (`pro`/`plus`)→tier güncelle. (zorunlu)
- [ ] (Ops.) `GET /api/subscription/plans` ile Plus/Pro kart metinlerini döndür;
      `code` = mağaza product id, `features` = madde listesi.
- [ ] RevenueCat App User ID'nin backend user id olduğunu doğrula.
