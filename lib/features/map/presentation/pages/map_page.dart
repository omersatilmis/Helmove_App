import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Sayfa açılır açılmaz GPS'i tetikliyoruz
    _determinePosition(); 
  }

  // 📍 GPS MOTORU: Konum izni alır ve koordinatları çeker
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Telefonun genel konum servisi açık mı?
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Konum servisleri kapalı.");
      return;
    }

    // 2. Uygulamaya izin verilmiş mi?
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("Konum izni reddedildi.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("Konum izni kalıcı olarak reddedildi.");
      return;
    }

    // 🚀 Her şey tamamsa konumu çek (En yüksek hassasiyetle)
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Widget hala ekranda mı kontrolü (Hata almamak için)
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      // Haritanın kamerasını senin olduğun yere uçur
      _mapController.move(_currentPosition!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Harita tam ekran olacak, AppBar yok
      body: _currentPosition == null
          ? const Center(
              // Konum bulunana kadar ekranda dönecek olan Helmove yükleme ekranı
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    "GPS Aranıyor...",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ],
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition!,
                initialZoom: 15.0, // Yakınlaştırma seviyesi (Sokakları görecek kadar)
              ),
              children: [
                // 🗺️ YARIN MAPBOX OLACAK OLAN GEÇİCİ ZEMİN (OSM)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.helmove', // İleride kendi paket adını yazarsın
                ),
                // 🏍️ SENİN KONUMUN (MARKER)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2), // Turuncu sinyal halesi
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.motorcycle,
                          color: Colors.orange, // Motor ikonu
                          size: 35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      // Sağ alttaki "Beni Bul / Merkeze Al" butonu
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: _determinePosition,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}