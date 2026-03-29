import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/core/widgets/app_input_field.dart';
import 'package:helmove/features/profile/presentation/providers/profile_provider.dart';
import 'package:helmove/core/widgets/app_frosted_button.dart';
import 'package:helmove/l10n/app_localizations.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // --- CONTROLLERLAR ---
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late TextEditingController _regionController;
  late TextEditingController _instaController;
  late TextEditingController _ytController;
  late TextEditingController _twitterController;

  bool _isChanged = false; // Kaydet butonu kontrolü
  File? _localCoverPhoto; // Arkaplan için yerel (geçici) dosya

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>();

    // Verileri doldur
    _firstNameController = TextEditingController(text: p.firstName);
    _lastNameController = TextEditingController(text: p.lastName);
    _usernameController = TextEditingController(text: p.username);
    _phoneController = TextEditingController(text: p.phoneNumber);
    _emailController = TextEditingController(text: p.email);
    _bioController = TextEditingController(text: p.bio);
    _cityController = TextEditingController(text: p.city);
    _regionController = TextEditingController(text: p.region);

    // Sosyal medya (Backend DTO'da henüz yoksa boş bırakırız)
    _instaController = TextEditingController();
    _ytController = TextEditingController();
    _twitterController = TextEditingController();

    // Değişiklik dinleyicilerini ekle
    _firstNameController.addListener(_checkChanges);
    _lastNameController.addListener(_checkChanges);
    _usernameController.addListener(_checkChanges);
    _phoneController.addListener(_checkChanges);
    _emailController.addListener(_checkChanges);
    _bioController.addListener(_checkChanges);
    _cityController.addListener(_checkChanges);
    _regionController.addListener(_checkChanges);
    _instaController.addListener(_checkChanges);
    _ytController.addListener(_checkChanges);
    _twitterController.addListener(_checkChanges);
  }

  void _checkChanges() {
    final p = context.read<ProfileProvider>();
    // Herhangi bir alan ilk halinden farklı mı?
    final changed =
        _firstNameController.text != p.firstName ||
        _lastNameController.text != p.lastName ||
        _usernameController.text != p.username ||
        _phoneController.text != (p.phoneNumber ?? "") ||
        _emailController.text != p.email ||
        _bioController.text != (p.bio ?? "") ||
        _cityController.text != (p.city ?? "") ||
        _regionController.text != (p.region ?? "") ||
        _instaController.text != (p.profile?.instagramUrl ?? "") ||
        _ytController.text != (p.profile?.youtubeUrl ?? "") ||
        _twitterController.text != (p.profile?.twitterUrl ?? "") ||
        _localCoverPhoto != null;

    if (changed != _isChanged) {
      setState(() => _isChanged = changed);
    }
  }

  @override
  void dispose() {
    // Controllerları temizle
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        // 🔥 Custom Frosted Button (Geri Tuşu)
        leading: Padding(
          padding: const EdgeInsets.all(8.0), // Kenarlardan nefes payı
          child: AppFrostedButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),

        title: Text(l10n.edit_profile, style: AppTextStyles.h3),
        centerTitle: true,

        actions: [
          TextButton(
            // Değişiklik varsa fonksiyon çalışır, yoksa null (tıklanmaz)
            onPressed: _isChanged ? () => _saveProfile() : null,
            child: Text(
              l10n.save,
              style: TextStyle(
                color: _isChanged
                    ? theme.colorScheme.primary
                    : theme.disabledColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPhotoSection(theme),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _sectionTitle(l10n.personal_info, theme),
                  AppInputField(
                    controller: _firstNameController,
                    label: l10n.firstName,
                    leadingIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  AppInputField(
                    controller: _lastNameController,
                    label: l10n.lastName,
                    leadingIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  AppInputField(
                    controller: _usernameController,
                    label: l10n.username,
                    leadingIcon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 12),
                  AppInputField(
                    controller: _bioController,
                    label: l10n.about,
                    leadingIcon: Icons.info_outline,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),
                  _sectionTitle(l10n.contactUs, theme),
                  AppInputField(
                    controller: _emailController,
                    label: l10n.email,
                    leadingIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 12),
                  AppInputField(
                    controller: _phoneController,
                    label: "Telefon",
                    leadingIcon: Icons.phone_android_outlined,
                  ),

                  const SizedBox(height: 24),
                  _sectionTitle(l10n.currentLocation, theme),
                  Row(
                    children: [
                      Expanded(
                        child: AppInputField(
                          controller: _cityController,
                          label: l10n.city,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppInputField(
                          controller: _regionController,
                          label: l10n.region,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final success = await context.read<ProfileProvider>().updateLocation(0, 0); // Mock for now or use Geolocation
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.updated)),
                          );
                        }
                    },
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: Text(l10n.update_location_now),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionTitle("Sosyal Medya", theme),
                  AppInputField(
                    controller: _instaController,
                    label: "Instagram",
                    leadingIcon: Icons.camera_alt_outlined,
                  ),
                  const SizedBox(height: 12),
                  AppInputField(
                    controller: _ytController,
                    label: "YouTube",
                    leadingIcon: Icons.play_circle_outline,
                  ),
                  const SizedBox(height: 12),
                  AppInputField(
                    controller: _twitterController,
                    label: "Twitter (X)",
                    leadingIcon: Icons.telegram_outlined,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(
        title,
        style: AppTextStyles.h3.copyWith(
          fontSize: 16,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    // Profil fotosu provider'dan (güncellenirse orası değişiyor)
    final provider = context.watch<ProfileProvider>();
    final profileUrl = provider.profileImageUrl;

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // --- ARKA PLAN (KAPAK) FOTOĞRAFI ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 60,
            child: GestureDetector(
              onTap: () => _pickImage(isProfilePhoto: false),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_localCoverPhoto != null)
                        Image.file(_localCoverPhoto!, fit: BoxFit.cover)
                      else if (provider.profile?.coverImageUrl != null)
                        CachedNetworkImage(
                          imageUrl: provider.profile!.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                        )
                      else
                        Image.asset(
                          'assets/images/profile_bg_photo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: theme.colorScheme.primary.withValues(alpha:
                                  0.1,
                                ),
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                        ),
                      // Modern Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha:0.4),
                            ],
                          ),
                        ),
                      ),
                      // Edit Icon for Cover
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha:0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: const Icon(
                            Icons.camera_enhance_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- PROFİL FOTOĞRAFI ---
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: () => _pickImage(isProfilePhoto: true),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: profileUrl != null
                          ? CachedNetworkImageProvider(profileUrl) as ImageProvider
                          : const AssetImage('assets/icons/ic_profile.png'),
                    ),
                  ),
                  // Profile Edit Badge
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage({required bool isProfilePhoto}) async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();

    // Modern Kaynak Seçimi (Bottom Sheet)
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              isProfilePhoto
                  ? l10n.change_profile_photo
                  : "Kapak Fotoğrafını Değiştir",
              style: AppTextStyles.h3.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sourceButton(
                  context: context,
                  icon: Icons.camera_alt_rounded,
                  label: "Kamera",
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                _sourceButton(
                  context: context,
                  icon: Icons.photo_library_rounded,
                  label: "Galeri",
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );

      if (pickedFile != null && mounted) {
        if (isProfilePhoto) {
          final provider = context.read<ProfileProvider>();
          final success = await provider.updateProfilePicture(pickedFile.path);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profil fotoğrafı güncellendi')),
            );
          }
        } else {
          setState(() {
            _localCoverPhoto = File(pickedFile.path);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kapak fotoğrafı seçildi (Önizleme)')),
          );
        }
      }
    } catch (e) {
      debugPrint("Resim seçme hatası: $e");
    }
  }

  Widget _sourceButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.medium),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    // 1. Klavyeyi kapat
    FocusScope.of(context).unfocus();

    // 2. Provider'a update isteği at
    final provider = context.read<ProfileProvider>();
    final success = await provider.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      bio: _bioController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      region: _regionController.text.trim(),
      instagramUrl: _instaController.text.trim(),
      youtubeUrl: _ytController.text.trim(),
      twitterUrl: _twitterController.text.trim(),
    );

    // 3. Kapak fotoğrafı değişikliği varsa onu da yükle
    if (success && _localCoverPhoto != null) {
      await provider.updateCoverPhoto(_localCoverPhoto!.path);
    }

    if (success && mounted) {
      setState(() => _isChanged = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profile_updated_success)),
      );
      if (mounted) Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
