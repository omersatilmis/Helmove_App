import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/core/widgets/app_input_field.dart';
import 'package:moto_comm_app_1/features/profile/presentation/providers/profile_provider.dart';
import 'package:moto_comm_app_1/core/widgets/app_button_frosted.dart'; // 👈 Import burada

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
        _regionController.text != (p.region ?? "");

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

        title: Text("Profili Düzenle", style: AppTextStyles.h3),
        centerTitle: true,

        actions: [
          TextButton(
            // Değişiklik varsa fonksiyon çalışır, yoksa null (tıklanmaz)
            onPressed: _isChanged ? () => _saveProfile() : null,
            child: Text(
              "Kaydet",
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
                  _sectionTitle("Kişisel Bilgiler"),
                  AppInputField(
                    controller: _firstNameController,
                    label: "Ad",
                    leadingIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  AppInputField(
                    controller: _lastNameController,
                    label: "Soyad",
                    leadingIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  AppInputField(
                    controller: _usernameController,
                    label: "Kullanıcı Adı",
                    leadingIcon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 12),
                  AppInputField(
                    controller: _bioController,
                    label: "Hakkında",
                    leadingIcon: Icons.info_outline,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),
                  _sectionTitle("İletişim"),
                  AppInputField(
                    controller: _emailController,
                    label: "E-Posta",
                    leadingIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 12),
                  AppInputField(
                    controller: _phoneController,
                    label: "Telefon",
                    leadingIcon: Icons.phone_android_outlined,
                  ),

                  const SizedBox(height: 24),
                  _sectionTitle("Konum"),
                  Row(
                    children: [
                      Expanded(
                        child: AppInputField(
                          controller: _cityController,
                          label: "Şehir",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppInputField(
                          controller: _regionController,
                          label: "Bölge",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {}, // API: PUT /api/Profile/me/location
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text("Konumu Şimdi Güncelle"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionTitle("Sosyal Medya"),
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(
        title,
        style: AppTextStyles.h3.copyWith(
          fontSize: 16,
          color: Colors.deepOrange,
        ),
      ),
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    // Profil fotosu provider'dan (güncellenirse orası değişiyor)
    final provider = context.watch<ProfileProvider>();
    final profileUrl = provider.profileImageUrl;

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Arka Plan Fotoğrafı
          Positioned.fill(
            bottom: 40,
            child: GestureDetector(
              onTap: () => _pickImage(isProfilePhoto: false),
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_localCoverPhoto != null)
                      Image.file(
                        _localCoverPhoto!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    else
                      Image.asset(
                        'assets/images/profile_bg_photo.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    Container(color: Colors.black26),
                    const Icon(
                      Icons.camera_enhance_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Profil Fotoğrafı
          GestureDetector(
            onTap: () => _pickImage(isProfilePhoto: true),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: theme.scaffoldBackgroundColor,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileUrl != null
                    ? NetworkImage(profileUrl) as ImageProvider
                    : const AssetImage('assets/icons/ic_profile.png'),
                child: const Icon(
                  Icons.add_a_photo,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage({required bool isProfilePhoto}) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        if (isProfilePhoto) {
          // Profil fotosu -> Backend'e hemen yükle
          final provider = context.read<ProfileProvider>();
          final success = await provider.updateProfilePicture(pickedFile.path);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profil fotoğrafı güncellendi')),
            );
          }
        } else {
          // Kapak fotosu -> Sadece local göster (Backend entity'de yoksa)
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

  Future<void> _saveProfile() async {
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
    );

    if (success && mounted) {
      setState(() => _isChanged = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi')),
      );
      Navigator.pop(context); // İsteğe göre kapatabiliriz veya kalabiliriz
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
