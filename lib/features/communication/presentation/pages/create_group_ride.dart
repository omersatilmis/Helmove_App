import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- PROJE İMPORTLARI ---
import '../../../../core/theme/text_styles.dart';
// Merkezi Input
import '../../../../core/widgets/app_input_field.dart';
// Merkezi Butonlar (İkon ve Text için)
import '../../../../core/widgets/app_frosted_button.dart';
import '../../../../core/widgets/app_background.dart';
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
  final TextEditingController _descriptionController = TextEditingController();

  // Durum değişkenleri
  String selectedPrivacy = 'Public';
  String selectedDifficulty = 'Beginner';
  String selectedRidingStyle = 'Sakin';

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
    _descriptionController.dispose();
    super.dispose();
  }

  // İşleme Devam Et
  void _onProceed() {
    FocusManager.instance.primaryFocus?.unfocus();

    final groupName = _groupNameController.text.trim();
    final finalGroupName = groupName.isNotEmpty ? groupName : "Weekend Riders";
    final maxParticipants = participantOptions[selectedMaxParticipantsKey] ?? 6;

    final descriptionText = _descriptionController.text.trim();

    // InviteArgs.fromExtra() Map yapısına uygun format:
    //   sessionId  → 0 (henüz oluşturulmadı, invite sonrası oluşacak)
    //   isFromCreateGroup → true  (redirect guard'ın isValid kontrolü için gerekli)
    //   groupData  → grup oluşturma bilgileri
    final data = {
      'isFromCreateGroup': true,
      'groupData': {
        'groupName': finalGroupName,
        'maxParticipants': maxParticipants,
        'privacy': selectedPrivacy,
        'destination': _destinationController.text.trim(),
        'ridingStyle': selectedRidingStyle,
        'difficulty': selectedDifficulty,
        'description': descriptionText.isNotEmpty
            ? descriptionText
            : "belirlenmedi",
      },
    };

    context.push('/communication/invite', extra: data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Klavye yüksekliğini al
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;


    return AppBackground(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // Konumlandırmayı biz Stack ile manuel yöneteceğiz
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              // --- 1. HEADER (ŞEFFAF ÜST BAR) ---
              Padding(
                padding: EdgeInsets.only(
                  top: topPadding + 6,
                  bottom: 8,
                  left: 16,
                  right: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      "Grup Oluştur",
                      style: AppTextStyles.h3.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 42), // Balance the row
                  ],
                ),
              ),

              // --- 2. SCROLLABLE CONTENT & FAB ---
              Expanded(
                child: Stack(
                  children: [
                    // --- SCROLL CONTENT ---
                    Positioned.fill(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          top: 8.0,
                          bottom: bottomInset > 0
                              ? bottomInset + 100
                              : bottomPadding + 100,
                          left: 20.0,
                          right: 20.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),

                            // Grup Adı
                            _buildFieldLabel("Grup Adı"),
                            const SizedBox(height: 8),
                            AppInputField(
                              controller: _groupNameController,
                              hint: "Grup Adı (Örn: Hafta Sonu Turu)",
                              leadingIcon: Icons.group,
                            ),

                            const SizedBox(height: 16),

                            // Maksimum Sürücü
                            _buildFieldLabel("Maksimum Sürücü"),
                            const SizedBox(height: 8),
                            _buildGlassDropdown(colorScheme),

                            const SizedBox(height: 16),

                            // Gizlilik
                            _buildFieldLabel("Grup Gizliliği"),
                            const SizedBox(height: 8),
                            _buildAccordionSelector(
                              context: context,
                              title: selectedPrivacy == 'Public'
                                  ? 'Herkese Açık'
                                  : 'Özel',
                              options: const ['Herkese Açık', 'Özel'],
                              onSelected: (val) => setState(
                                () => selectedPrivacy =
                                    val == 'Herkese Açık' ? 'Public' : 'Private',
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Hedef
                            _buildFieldLabel("Rota / Hedef (Opsiyonel)"),
                            const SizedBox(height: 8),
                            AppInputField(
                              controller: _destinationController,
                              hint: "Örn: Abant Gölü, Sapanca",
                              leadingIcon: Icons.map,
                            ),

                            const SizedBox(height: 16),

                            // Sürüş Tarzı ve Zorluk
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel("Sürüş Tarzı"),
                                      const SizedBox(height: 8),
                                      _buildAccordionSelector(
                                        context: context,
                                        title: selectedRidingStyle,
                                        options: [
                                          'Sakin',
                                          'Tour',
                                          'Viraj',
                                          'Sehir',
                                        ],
                                        onSelected: (val) => setState(
                                          () => selectedRidingStyle = val,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel("Zorluk"),
                                      const SizedBox(height: 8),
                                      _buildAccordionSelector(
                                        context: context,
                                        title: selectedDifficulty,
                                        options: [
                                          'Beginner',
                                          'Intermediate',
                                          'Advanced',
                                          'Expert',
                                        ],
                                        onSelected: (val) => setState(
                                          () => selectedDifficulty = val,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Açıklama
                            _buildFieldLabel("Açıklama"),
                            const SizedBox(height: 8),
                            AppInputField(
                              controller: _descriptionController,
                              hint: "Sürüş hakkında kısa bir açıklama yazın...",
                              leadingIcon: Icons.description,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- 3. FLOATING ACTION BUTTON (KLAVYEYE DUYARLI) ---
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutQuad,
                      bottom: bottomInset > 0
                          ? bottomInset + 16
                          : bottomPadding + 20,
                      left: 20,
                      right: 20,
                      child: AppFrostedTextButton(
                        text: "Kullanıcı Davet Et",
                        height: 56,
                        backgroundColor:
                            colorScheme.primary, // Turuncu arka plan
                        textColor: colorScheme.onPrimary, // Beyaz yazı
                        onPressed: _onProceed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildGlassDropdown(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMaxParticipantsKey,
          dropdownColor: colorScheme.surfaceContainerHigh,
          icon: Icon(Icons.expand_more_rounded, color: colorScheme.primary),
          isExpanded: true,
          style: AppTextStyles.bodyLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
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

  Widget _buildFieldLabel(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: AppTextStyles.inputLabel.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAccordionSelector({
    required BuildContext context,
    required String title,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          title: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w300,
            ),
          ),
          iconColor: colorScheme.primary,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          children: options.map((opt) {
            final isOptSelected = opt == title;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text(
                opt,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isOptSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w300,
                ),
              ),
              onTap: () {
                onSelected(opt);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
