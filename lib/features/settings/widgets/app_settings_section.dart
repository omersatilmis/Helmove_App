import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/settings/widgets/settings_section_header.dart';

// 🔥 YENİ OLUŞTURDUĞUMUZ HELPER DOSYASINI IMPORT ET
import 'package:flutter_application_1/features/settings/widgets/helper_widgets.dart';

class AppSettingsSection extends StatefulWidget {
  const AppSettingsSection({super.key});

  @override
  State<AppSettingsSection> createState() => _AppSettingsSectionState();
}

class _AppSettingsSectionState extends State<AppSettingsSection> {
  // State Değişkenleri
  bool _noiseCancellation = false;
  bool _voiceNavigation = true;
  bool _wifiOnly = true;

  String _distanceUnit = "Kilometre (km)";
  String _tempUnit = "Celsius (°C)";

  String _mapType = "Normal";
  bool _trafficEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: "Uygulama Ayarları"),

                // 3. ÖLÇÜ BİRİMLERİ
        SettingsExpansionTile(
          icon: Icons.straighten_rounded,
          title: "Ölçü Birimleri",
          children: [
            SettingsActionTile(
              title: "Mesafe",
              value: _distanceUnit,
              icon: Icons.directions_car_rounded,
              onTap: () => showSettingsBottomSheet(
                context, "Mesafe Birimi", ["Kilometre (km)", "Mil (mi)"], 
                (val) => setState(() => _distanceUnit = val)
              ),
            ),
            SettingsActionTile(
              title: "Sıcaklık",
              value: _tempUnit,
              icon: Icons.thermostat_rounded,
              onTap: () => showSettingsBottomSheet(
                context, "Sıcaklık Birimi", ["Celsius (°C)", "Fahrenheit (°F)"], 
                (val) => setState(() => _tempUnit = val)
              ),
            ),
          ],
        ),

        // 4. HARİTA AYARLARI
        SettingsExpansionTile(
          icon: Icons.map_outlined,
          title: "Harita Ayarları",
          children: [
            SettingsActionTile(
              title: "Harita Tipi",
              value: _mapType,
              icon: Icons.layers_outlined,
              onTap: () => showSettingsBottomSheet(
                context, "Harita Tipi", ["Normal", "Uydu", "Arazi", "Hibrit"], 
                (val) => setState(() => _mapType = val)
              ),
            ),
            SettingsSwitchTile(
              title: "Trafik Bilgisi", 
              subtitle: "Yoğunluk durumunu göster", 
              value: _trafficEnabled, 
              onChanged: (val) => setState(() => _trafficEnabled = val)
            ),
          ],
        ),

        // 5. SES & MEDYA
        SettingsExpansionTile(
          icon: Icons.volume_up_rounded,
          title: "Ses & Medya",
          children: [
            SettingsSwitchTile(
              title: "Gürültü Engelleme", 
              subtitle: "Rüzgar sesini azaltır", 
              value: _noiseCancellation, 
              onChanged: (val) => setState(() => _noiseCancellation = val)
            ),
            SettingsSwitchTile(
              title: "Sesli Navigasyon", 
              subtitle: "Rota talimatlarını sesli al", 
              value: _voiceNavigation, 
              onChanged: (val) => setState(() => _voiceNavigation = val)
            ),
          ],
        ),

        // 6. BAĞLANTI
        SettingsExpansionTile(
          icon: Icons.sensors_rounded,
          title: "Bağlantı",
          children: [
            SettingsSwitchTile(
              title: "Sadece Wi-Fi ile İndir", 
              subtitle: "Harita güncellemeleri için", 
              value: _wifiOnly, 
              onChanged: (val) => setState(() => _wifiOnly = val)
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text("Bluetooth Cihazları", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}