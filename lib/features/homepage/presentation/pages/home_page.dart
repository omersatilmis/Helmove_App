import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// 🔥 DİKKAT: Drawer'ı dışarıdan kontrol etmek için bu import şart!
import 'package:moto_comm_app_1/app/bottom_bar.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/features/profile/presentation/providers/profile_provider.dart';

class HomePageWithDrawer extends StatefulWidget {
  const HomePageWithDrawer({super.key});

  @override
  State<HomePageWithDrawer> createState() => _HomePageWithDrawerState();
}

class _HomePageWithDrawerState extends State<HomePageWithDrawer> {
  late String _visorMessage; // Sayfa açıldığında seçilecek mesaj

  @override
  void initState() {
    super.initState();
    _visorMessage = _getRandomMotoMessage(); // İlk mesajı belirle

    // Sayfa açıldığında profil verilerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final firstName = profileProvider.firstName;
    final lastName = profileProvider.lastName;
    final profileImage =
        profileProvider.profileImageUrl ?? 'https://i.pravatar.cc/150?img=11';

    final theme = Theme.of(context);

    return Scaffold(
      // --- APP BAR ---
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 300, // Selamlama alanı için genişlik
        leading: GestureDetector(
          onTap: () {
            // MainWrapper'daki Drawer'ı açar
            mainScaffoldKey.currentState?.openDrawer();
          },
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(profileImage),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: AppTextStyles.regular.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      Text(
                        "$firstName $lastName",
                        style: AppTextStyles.bold.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // MESAJLAR
          IconButton(
            icon: Image.asset(
              'assets/icons/ic_message.png',
              width: 30, // Boyutu buradan ayarla
              height: 30,
              color: theme
                  .colorScheme
                  .onSurface, // Temaya göre ikon rengini belirle
            ),
            onPressed: () => context.push('/messages'),
          ),

          // BİLDİRİMLER
          IconButton(
            icon: Image.asset(
              'assets/icons/ic_bell.png',
              width: 30,
              height: 30,
              color: theme.colorScheme.onSurface, // Işık/Karanlık mod uyumu
            ),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],

        // --- VİZÖR MESAJI ALANI (AppBar Bottom) ---
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              // Hafif transparan marka rengi
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _visorMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: const Center(child: Text("Akış (Feed) İçeriği Gelecek")),
    );
  }

  /// Günün vaktine göre selamlama ve emoji döndürür
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return "🌅 Günaydın";
    if (hour >= 11 && hour < 17) return "☀️ İyi günler";
    if (hour >= 17 && hour < 21) return "🌇 İyi akşamlar";
    if (hour >= 21 && hour <= 23) return "🌃 İyi geceler";
    return "🌌 Dikkatli sür";
  }

  /// Rastgele bir motorcu mesajı döndürür
  String _getRandomMotoMessage() {
    final List<String> messages = [
      "Depon dolu, virajın bol olsun! 🏍️",
      "Bakkala bile ekipmansız gitmiyoruz, değil mi? 🤨",
      "Benzin kaç para oldu haberin var mı usta? ⛽",
      "Vizörün temiz, yolun açık olsun. ✨",
      "Tekerine taş, gözüne yaş değmesin. ✨",
      "Motoru tozlu gördüm, bir ara yıka istersen... 🤔",
      "Motor biraz tozlanmış… demek ki güzel anılar birikmiş 😏",
      "Ekipman tamam mı? Cool görünmekten önce sağlam dönelim eve 😎",
      "Tekerin düz bassın da rota neresi olursa olsun 😌",
      "Vizör temiz, kafanın karışık olabilir, dert etme, biz varız ✨",
      "Ekipmanına önem ver, bizim için kıymetlisin 😎",
      "Motorun sesi moralinden yüksek olsun 🎵🏍️",
      "Vites mi o? Ben ayak ucuyla piyano çalıyorum sanmıştım. 🎹",
      "Tekerin yere bassın ama aklın havada kalmasın. ✌️",
      "O egzoz sesiyle anca mahalleye iftar vaktini haber verirsin. 🔊",
      "Virajda motoru yatıramıyorsan söyle, yan ayaklığı açalım. 📉",
      "Kaskı kola takınca koruma sağlamıyor, 'Pro' kardeş. 🦾",
      "Ekipman hayat kurtarır, kaskı takmayı unutma!",
      "Asfalt ağlıyor be, yavaş biraz! 💨",
      "Yine hangi rotanın hayalini kuruyorsun? 🤔",
      "Motorcu selamını vermeyi unutma!",
      "Hava yağmurlu diye motoru çıkarmadın mı? Şeker misin sen? 🍭",

      //Premium için şimdilik yorum satırı olarak kaslın.
      /*
      "Standart üyelik mi? Bu hızla viraja girilmez, vizyonu büyüt. 📈",
      "Kaskın güzel ama altındaki motor 'Premium' diye bağırıyor... Şaka şaka. 🤡",
      "Ekipmanlar pırıl pırıl ama profilinde neden 'Gold' rozeti yok? ✨",
      "Buralar hep standart kullanıcı dolu, elit bir hava lazım... 🧐",
      "Senin motorun sesi güzel ama Premium üyenin sesi bir başka çıkıyor. 🔊",
      "Yollar senin ama ayrıcalıklar sadece seçkin sürücülerin. 😉",
      "Yollar seni yoruyorsa, belki de Premium konforuna geçme vaktindir? ⛽",
      "Herkes sürer ama sadece bazıları 'iz' bırakır. Rozetin nerede? 🛡️",
      "Bu mesajı görüyorsan hala kalabalıktasın. Zirveye çıkmak ister misin? 🏔️",
      "Sıradan bir sürücü mü, yoksa topluluğun lideri mi? Karar senin. 👑",
      */
    ];
    return (messages..shuffle()).first;
  }
}
