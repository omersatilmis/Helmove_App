import 'package:flutter/material.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Harita genelde tüm ekranı kaplar, AppBar koymayabiliriz
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.orange), // Harita vurgusu
            SizedBox(height: 16),
            Text("Google Maps / Sürüş Haritası"),
          ],
        ),
      ),
    );
  }
}
