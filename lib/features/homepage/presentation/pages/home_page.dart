import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 🔥 DİKKAT: Drawer'ı dışarıdan kontrol etmek için bu import şart!
import 'package:moto_comm_app_1/app/bottom_bar.dart'; 

class HomePageWithDrawer extends StatelessWidget {
  const HomePageWithDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Burada 'key' veya 'drawer' kullanmıyoruz.
      // Çünkü Drawer artık bir üst katmanda (BottomBarWrapper).

      // --- APP BAR ---
      appBar: AppBar(
        automaticallyImplyLeading: false, // Varsayılan hamburgeri kapat
        leadingWidth: 200, // Sol tarafı genişlet
        leading: GestureDetector(
          onTap: () {
            // 🔥 KRİTİK NOKTA:
            // Kendi scaffold'umuzu değil, en dıştaki (MainWrapper) scaffold'u açıyoruz.
            // Böylece Drawer, BottomBar'ın üzerinde açılıyor.
            mainScaffoldKey.currentState?.openDrawer();
          },
          child: Container(
            color: Colors.transparent, // Tıklama alanını doldur
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Merhaba,", 
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)
                      ),
                      Text(
                        "Ahmet Yılmaz", 
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), 
                        overflow: TextOverflow.ellipsis
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        actions: [
          // MESAJLAR BUTONU
          IconButton(
            icon: Image.asset(
              'assets/icons/ic_message.png', // ⚠️ Bu dosyanın assets klasöründe olduğundan emin ol
              width: 24, 
              height: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => context.push('/messages'),
          ),

          // BİLDİRİMLER BUTONU
          IconButton(
            icon: Image.asset(
              'assets/icons/ic_bell.png', // ⚠️ Bu dosyanın assets klasöründe olduğundan emin ol
              width: 24, 
              height: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      
      body: const Center(child: Text("Akış (Feed) İçeriği Gelecek")),
    );
  }
}
