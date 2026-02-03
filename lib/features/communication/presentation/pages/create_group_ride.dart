import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/glass_input_field.dart';
import '../../domain/entities/group_ride_data.dart';

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
  String selectedPrivacy = 'Public'; // 'Public' veya 'Private'
  String selectedMaxParticipants = '6 riders'; // Dropdown değeri

  @override
  void dispose() {
    _groupNameController.dispose();
    _destinationController.dispose();
    _ridingStyleController.dispose();
    super.dispose();
  }

  final List<String> riderOptions = [
    '4 riders',
    '6 riders',
    '8 riders',
    '10 riders',
    '12 riders',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Dinamik arka plan gradyanı
    final backgroundGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A100A), // Koyu modda hafif kırmızımsı üst
              Color(0xFF12100E), // darkBackground
            ],
            stops: [0.0, 0.4],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(
                alpha: 0.1,
              ), // Açık modda hafif turuncu
              colorScheme.surface,
            ],
            stops: const [0.0, 0.4],
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          gradient: backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Back Button & Title)
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow.withOpacity(
                            0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.1),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: colorScheme.onSurface,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
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

                  const SizedBox(height: 30),

                  // 1. Group Name
                  GlassInputField(
                    controller: _groupNameController,
                    label: "Group Name",
                    hintText: "Weekend Ride",
                  ),

                  const SizedBox(height: 20),

                  // 2. Maximum Riders (Dropdown)
                  Text(
                    "Maximum Riders",
                    style: AppTextStyles.inputLabel.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMaxParticipants,
                        dropdownColor: colorScheme.surfaceContainerLow,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: colorScheme.onSurface,
                        ),
                        isExpanded: true,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        items: riderOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedMaxParticipants = newValue!;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Group Privacy
                  Text(
                    "Group Privacy",
                    style: AppTextStyles.inputLabel.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPrivacyCard(
                          // BURADA textStyle parametresini artık kullanabiliriz
                          textStyle: AppTextStyles.bodyLarge.copyWith(
                            fontSize: 20, // Boyutu buradan kontrol edebilirsin
                          ),
                          title: "Public",
                          subtitle: "Anyone can join",
                          icon: Icons.language,
                          isSelected: selectedPrivacy == 'Public',
                          onTap: () =>
                              setState(() => selectedPrivacy = 'Public'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPrivacyCard(
                          textStyle: AppTextStyles.bodyLarge.copyWith(
                            fontSize: 20,
                          ),
                          title: "Private",
                          subtitle: "Invite only",
                          icon: Icons.lock_outline,
                          isSelected: selectedPrivacy == 'Private',
                          onTap: () =>
                              setState(() => selectedPrivacy = 'Private'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 4. Destination
                  GlassInputField(
                    controller: _destinationController,
                    label: "Hedef Noktası (Opsiyonel)",
                    hintText: "Örn: Abant Gölü, Sapanca",
                  ),

                  const SizedBox(height: 20),

                  // 5. Riding Style
                  GlassInputField(
                    controller: _ridingStyleController,
                    label: "Sürüş Tarzı",
                    hintText: "Sakin Sürüş",
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final data = GroupRideData(
                          groupName: _groupNameController.text.isNotEmpty
                              ? _groupNameController.text
                              : "Weekend Riders",
                          maxParticipants:
                              int.tryParse(
                                selectedMaxParticipants.split(' ')[0],
                              ) ??
                              6,
                          privacy: selectedPrivacy,
                          destination: _destinationController.text.isNotEmpty
                              ? _destinationController.text
                              : "",
                          ridingStyle: _ridingStyleController.text.isNotEmpty
                              ? _ridingStyleController.text
                              : "data.ridingStyle",
                        );
                        context.push('/group-page', extra: data);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        "Create Ride",
                        style: AppTextStyles.button.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- DÜZELTİLEN YER ---
  // textStyle parametresi eklendi ve içeride kullanıldı
  Widget _buildPrivacyCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    TextStyle? textStyle, // Yeni parametre
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Başlık Stili Düzeltildi
            Text(
              title,
              style:
                  textStyle?.copyWith(
                    // Eğer dışarıdan stil geldiyse rengini duruma göre ez
                    color: isSelected ? colorScheme.primary : textStyle.color,
                    fontWeight: FontWeight.bold,
                  ) ??
                  // Dışarıdan gelmediyse varsayılan bir stil kullan (h3 yerine daha uygun bir boyut)
                  AppTextStyles.bodyLarge.copyWith(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Varsayılan boyut
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
