import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../../../../core/widgets/app_frosted_button.dart';
// import '../../domain/entities/group_ride_data.dart';
// import '../bloc/group_ride_bloc.dart';
// import '../bloc/group_ride_event.dart';
// import '../bloc/group_ride_state.dart';

class GroupSettings extends StatefulWidget {
  final dynamic data;
  final ScrollController? scrollController;

  const GroupSettings({super.key, required this.data, this.scrollController});

  @override
  State<GroupSettings> createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings> {
  // Kontrolcüler
  late TextEditingController _groupNameController;
  late TextEditingController _destinationController;
  late TextEditingController _ridingStyleController;

  // Durum değişkenleri
  late String selectedPrivacy;
  late String selectedMaxParticipantsKey;

  // Katılımcı Seçenekleri (Map)
  final Map<String, int> participantOptions = {
    '4 riders': 4,
    '6 riders': 6,
    '8 riders': 8,
    '10 riders': 10,
    '12 riders': 12,
  };

  @override
  void initState() {
    super.initState();
    final groupName = widget.data is Map
        ? widget.data["groupName"]
        : widget.data.groupName;
    final destination = widget.data is Map
        ? widget.data["destination"]
        : widget.data.destination;
    final ridingStyle = widget.data is Map
        ? widget.data["ridingStyle"]
        : widget.data.ridingStyle;
    final privacy = widget.data is Map
        ? widget.data["privacy"]
        : widget.data.privacy;
    final maxParticipants = widget.data is Map
        ? widget.data["maxParticipants"]
        : widget.data.maxParticipants;

    _groupNameController = TextEditingController(text: groupName);
    _destinationController = TextEditingController(text: destination);
    _ridingStyleController = TextEditingController(text: ridingStyle);
    selectedPrivacy = privacy ?? "Private";

    final matchingKey = participantOptions.keys.firstWhere(
      (k) => participantOptions[k] == maxParticipants,
      orElse: () => '6 riders',
    );
    selectedMaxParticipantsKey = matchingKey;
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _destinationController.dispose();
    _ridingStyleController.dispose();
    super.dispose();
  }

  // Güncelleme İşlemi
  void _onUpdate() {
    FocusManager.instance.primaryFocus?.unfocus();
    // Logic temporarily disabled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Mock Update: Ayarlar güncellendi (Backend kapalı)"),
      ),
    );
  }

  void _onDelete() {
    // Logic temporarily disabled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Mock Delete: Oturum sonlandırıldı (Backend kapalı)"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A100A), Color(0xFF12100E)],
            stops: [0.0, 0.4],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.08),
              colorScheme.surface,
              colorScheme.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          );

    final labelStyle = AppTextStyles.inputLabel.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );

    return Builder(
      builder: (context) {
        final isLoading = false;

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Center(
              child: AppFrostedButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
                size: 40,
              ),
            ),
            centerTitle: true,
            title: Text(
              "Grup Ayarları",
              style: AppTextStyles.h3.copyWith(color: colorScheme.onSurface),
            ),
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: backgroundGradient),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 60),

                      const SizedBox(height: 10), // Boşluk azaltıldı
                      // --- 1. GRUP ADI ---
                      Text("Grup Adı", style: labelStyle),
                      const SizedBox(height: 4), // Boşluk azaltıldı
                      AppInputField(
                        controller: _groupNameController,
                        hint: "Grup Adı",
                        leadingIcon: Icons.group,
                      ),

                      const SizedBox(height: 10), // Boşluk azaltıldı
                      // --- 2. MAKSİMUM SÜRÜCÜ ---
                      Text("Maksimum Sürücü", style: labelStyle),
                      const SizedBox(height: 4),
                      _buildGlassDropdown(colorScheme),

                      const SizedBox(height: 10), // Boşluk azaltıldı
                      // --- 3. GİZLİLİK (YENİ TASARIM) ---
                      Text("Grup Gizliliği", style: labelStyle),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPrivacyCard(
                              title: "Herkese Açık",
                              subtitle: "Herkes katılabilir",
                              icon: Icons.public,
                              isSelected: selectedPrivacy == 'Public',
                              onTap: () =>
                                  setState(() => selectedPrivacy = 'Public'),
                            ),
                          ),
                          const SizedBox(width: 8), // Kart arası boşluk
                          Expanded(
                            child: _buildPrivacyCard(
                              title: "Özel",
                              subtitle: "Sadece davetliler",
                              icon: Icons.lock_outline,
                              isSelected: selectedPrivacy == 'Private',
                              onTap: () =>
                                  setState(() => selectedPrivacy = 'Private'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10), // Boşluk azaltıldı
                      // --- 4. HEDEF ---
                      Text("Rota / Hedef", style: labelStyle),
                      const SizedBox(height: 4),
                      AppInputField(
                        controller: _destinationController,
                        hint: "Örn: Abant Gölü",
                        leadingIcon: Icons.map,
                      ),

                      const SizedBox(height: 10), // Boşluk azaltıldı
                      // --- 5. SÜRÜŞ TARZI ---
                      Text("Sürüş Tarzı", style: labelStyle),
                      const SizedBox(height: 4),
                      AppInputField(
                        controller: _ridingStyleController,
                        hint: "Örn: Sakin Sürüş",
                        leadingIcon: Icons.two_wheeler,
                      ),

                      const SizedBox(height: 24), // Buton üstü boşluk azaltıldı
                      // --- BUTONLAR ---
                      Row(
                        children: [
                          Expanded(
                            child: AppFrostedTextButton(
                              text: "Sonlandır",
                              height: 48,
                              backgroundColor: colorScheme.error.withOpacity(
                                0.1,
                              ),
                              textColor: colorScheme.error,
                              onPressed: _onDelete,
                              isLoading: isLoading,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppFrostedTextButton(
                              text: "Güncelle",
                              height: 48,
                              backgroundColor: colorScheme.primary.withOpacity(
                                0.1,
                              ),
                              textColor: colorScheme.primary,
                              onPressed: _onUpdate,
                              isLoading: isLoading,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // --- HELPER WIDGETS ---

  Widget _buildGlassDropdown(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMaxParticipantsKey,
          dropdownColor: colorScheme.surfaceContainerLow,
          icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface),
          isExpanded: true,
          style: AppTextStyles.bodyLarge.copyWith(color: colorScheme.onSurface),
          items: participantOptions.keys.map((String key) {
            return DropdownMenuItem<String>(value: key, child: Text(key));
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() => selectedMaxParticipantsKey = newValue);
            }
          },
        ),
      ),
    );
  }

  // YENİ GİZLİLİK KARTI TASARIMI
  Widget _buildPrivacyCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İKON VE BAŞLIK YAN YANA
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 20, // İkonu hafif küçülttük
                ),
                const SizedBox(width: 8),
                Expanded(
                  // Yazı taşarsa alt satıra geçsin diye
                  child: Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Başlık boyutu ayarlandı
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6), // Başlık ve açıklama arası
            // AÇIKLAMA ALTTA
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
