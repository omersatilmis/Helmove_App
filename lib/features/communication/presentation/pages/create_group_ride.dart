import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- PROJE İMPORTLARI ---
import '../../../../core/theme/text_styles.dart';
// Merkezi Input
import '../../../../core/widgets/app_input_field.dart';
// Merkezi Butonlar (İkon ve Text için)
import '../../../../core/widgets/app_frosted_button.dart';
// import '../../domain/entities/group_ride_data.dart';

class CreateGroupRide extends StatefulWidget {
  const CreateGroupRide({super.key});

  @override
  State<CreateGroupRide> createState() => _CreateGroupRideState();
}

class _CreateGroupRideState extends State<CreateGroupRide> {
  // Kontrolcüler
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _ridingStyleController = TextEditingController();

  // Durum değişkenleri
  String selectedPrivacy = 'Public';

  // Katılımcı Seçenekleri (Map)
  final Map<String, int> participantOptions = {
    '4 riders': 4,
    '6 riders': 6,
    '8 riders': 8,
    '10 riders': 10,
    '12 riders': 12,
  };

  late String selectedMaxParticipantsKey;

  @override
  void initState() {
    super.initState();
    // Varsayılan olarak 6 riders seçili gelsin
    selectedMaxParticipantsKey = participantOptions.keys.firstWhere(
      (k) => k.startsWith('6'),
      orElse: () => participantOptions.keys.first,
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _destinationController.dispose();
    _ridingStyleController.dispose();
    super.dispose();
  }

  // İşleme Devam Et
  void _onProceed() {
    FocusManager.instance.primaryFocus?.unfocus();

    final groupName = _groupNameController.text.trim();
    final finalGroupName = groupName.isNotEmpty ? groupName : "Weekend Riders";
    final maxParticipants = participantOptions[selectedMaxParticipantsKey] ?? 6;

    final data = {
      'groupName': finalGroupName,
      'maxParticipants': maxParticipants,
      'privacy': selectedPrivacy,
      'destination': _destinationController.text.trim(),
      'ridingStyle': _ridingStyleController.text.trim(),
    };

    context.push('/communication/invite', extra: data);
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

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // Stack yerine Column kullanıyoruz. Böylece Header üstte, Buton altta sabit kalır.
          body: SafeArea(
            child: Column(
              children: [
                // --- 1. HEADER (SABİT) ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    children: [
                      AppFrostedButton(
                        icon: Icons.arrow_back,
                        size: 44,
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Create Group Ride",
                        style: AppTextStyles.h2.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- 2. SCROLLABLE CONTENT (ORTA ALAN) ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // Grup Adı
                        AppInputField(
                          controller: _groupNameController,
                          hint: "Grup Adı (Örn: Hafta Sonu Turu)",
                          label: "Grup Adı",
                          leadingIcon: Icons.group,
                        ),

                        const SizedBox(height: 20),

                        // Maksimum Sürücü
                        Text(
                          "Maksimum Sürücü",
                          style: AppTextStyles.inputLabel.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildGlassDropdown(colorScheme),

                        const SizedBox(height: 20),

                        // Gizlilik
                        Text(
                          "Grup Gizliliği",
                          style: AppTextStyles.inputLabel.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                            const SizedBox(width: 12),
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

                        const SizedBox(height: 20),

                        // Hedef
                        AppInputField(
                          controller: _destinationController,
                          hint: "Örn: Abant Gölü, Sapanca",
                          label: "Rota / Hedef (Opsiyonel)",
                          leadingIcon: Icons.map,
                        ),

                        const SizedBox(height: 20),

                        // Sürüş Tarzı
                        AppInputField(
                          controller: _ridingStyleController,
                          hint: "Örn: Sakin Sürüş, Viraj",
                          label: "Sürüş Tarzı",
                          leadingIcon: Icons.two_wheeler,
                        ),

                        // Alt kısımda biraz boşluk bırakalım ki en son input klavye açılınca sıkışmasın
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // --- 3. FOOTER (SABİT BUTON) ---
                // GroupPage'deki "Leave Ride" butonu ile aynı padding ve yapı
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: AppFrostedTextButton(
                    text: "Kullanıcı Davet Et",
                    height: 52,
                    // Turuncu (Primary) Renk
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    textColor: colorScheme.primary,
                    onPressed: _onProceed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildGlassDropdown(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
        padding: const EdgeInsets.all(16),
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
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
