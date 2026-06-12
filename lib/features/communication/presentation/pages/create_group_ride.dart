import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- PROJE İMPORTLARI ---
import '../../../../core/theme/text_styles.dart';
// Merkezi Input
import '../../../../core/widgets/app_input_field.dart';
// Merkezi Butonlar (İkon ve Text için)
import '../../../../core/widgets/app_frosted_button.dart';
import '../../../../core/widgets/app_background.dart';
import 'package:helmove/l10n/app_localizations.dart';
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
  // Canonical backend değerleri: 'Sakin' | 'Tour' | 'Viraj' | 'Sehir'
  // (group_settings.dart ile aynı sözleşme)
  String selectedRidingStyle = 'Sakin';

  // Katılımcı Seçenekleri (Map)
  Map<String, int> get participantOptions {
    final curL10n = l10n;
    if (curL10n == null) return {};
    return {
      curL10n.ridersCount(4): 4,
      curL10n.ridersCount(6): 6,
      curL10n.ridersCount(8): 8,
      curL10n.ridersCount(10): 10,
      curL10n.ridersCount(12): 12,
    };
  }

  late String selectedMaxParticipantsKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Varsayılan olarak 6 riders seçili gelsin
    selectedMaxParticipantsKey = participantOptions.keys.firstWhere(
      (k) => k.contains('6'),
      orElse: () => participantOptions.keys.first,
    );
  }

  AppLocalizations? get l10n => AppLocalizations.of(context);

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

    if (l10n == null) return;

    final groupName = _groupNameController.text.trim();
    final finalGroupName = groupName.isNotEmpty ? groupName : l10n!.defaultGroupName;
    final maxParticipants = participantOptions[selectedMaxParticipantsKey] ?? 6;

    final descriptionText = _descriptionController.text.trim();

    // InviteArgs.fromExtra() Map yapısına uygun format:
    //   sessionId  → 0 (henüz oluşturulmadı, invite sonrası oluşacak)
    //   isFromCreateGroup → true  (redirect guard'ın isValid kontrolü için gerekli)
    //   groupData  → grup oluşturma bilgileri
    final curL10n = l10n!;
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
            : curL10n.notSpecified,
      },
    };

    context.push('/communication/invite', extra: data);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
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
                      l10n.createRideGroup,
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
                            _buildFieldLabel(l10n.groupName),
                            const SizedBox(height: 8),
                            AppInputField(
                              controller: _groupNameController,
                              hint: l10n.groupNameHint,
                              leadingIcon: Icons.group,
                            ),

                            const SizedBox(height: 16),

                            // Maksimum Sürücü
                            _buildFieldLabel(l10n.maxParticipants),
                            const SizedBox(height: 8),
                            _buildGlassDropdown(colorScheme),

                            const SizedBox(height: 16),

                            // Gizlilik
                            _buildFieldLabel(l10n.groupPrivacy),
                            const SizedBox(height: 8),
                            _buildAccordionSelector(
                              context: context,
                              title: selectedPrivacy == 'Public'
                                  ? l10n.pPublic
                                  : l10n.pPrivate,
                              options: [l10n.pPublic, l10n.pPrivate],
                              onSelected: (val) => setState(
                                () => selectedPrivacy =
                                    val == l10n.pPublic ? 'Public' : 'Private',
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Hedef
                            _buildFieldLabel(l10n.destinationOptional),
                            const SizedBox(height: 8),
                            AppInputField(
                              controller: _destinationController,
                              hint: l10n.destinationHint,
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
                                      _buildFieldLabel(l10n.ridingStyle),
                                      const SizedBox(height: 8),
                                      _buildAccordionSelector(
                                        context: context,
                                        title: selectedRidingStyle == 'Sakin'
                                            ? l10n.chill
                                            : selectedRidingStyle == 'Tour'
                                                ? l10n.tour
                                                : selectedRidingStyle == 'Viraj'
                                                    ? l10n.fast
                                                    : l10n.city,
                                        options: [
                                          l10n.chill,
                                          l10n.tour,
                                          l10n.fast,
                                          l10n.city
                                        ],
                                        onSelected: (val) => setState(
                                          () => selectedRidingStyle = val ==
                                                  l10n.chill
                                              ? 'Sakin'
                                              : val == l10n.tour
                                                  ? 'Tour'
                                                  : val == l10n.fast
                                                      ? 'Viraj'
                                                      : 'Sehir',
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
                                      _buildFieldLabel(l10n.difficulty),
                                      const SizedBox(height: 8),
                                      _buildAccordionSelector(
                                        context: context,
                                        title: selectedDifficulty == 'Beginner'
                                            ? l10n.beginner
                                            : selectedDifficulty ==
                                                    'Intermediate'
                                                ? l10n.intermediate
                                                : selectedDifficulty ==
                                                        'Advanced'
                                                    ? l10n.advanced
                                                    : l10n.expert,
                                        options: [
                                          l10n.beginner,
                                          l10n.intermediate,
                                          l10n.advanced,
                                          l10n.expert
                                        ],
                                        onSelected: (val) => setState(
                                          () => selectedDifficulty = val ==
                                                  l10n.beginner
                                              ? 'Beginner'
                                              : val == l10n.intermediate
                                                  ? 'Intermediate'
                                                  : val == l10n.advanced
                                                      ? 'Advanced'
                                                      : 'Expert',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Açıklama
                            _buildFieldLabel(l10n.description),
                            const SizedBox(height: 8),
                            AppInputField(
                              controller: _descriptionController,
                              hint: l10n.descriptionHint,
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
                        text: l10n.inviteUsers,
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
