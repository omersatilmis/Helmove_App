import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/core/widgets/app_input_field.dart';
import 'package:moto_comm_app_1/features/profile/presentation/providers/profile_provider.dart';

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
        _firstNameController.text != (p.firstName ?? "") ||
        _lastNameController.text != (p.lastName ?? "") ||
        _usernameController.text != (p.username ?? "") ||
        _phoneController.text != (p.phoneNumber ?? "") ||
        _emailController.text != (p.email ?? "") ||
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
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
          ), // Çıkış hissi için X veya geri oku
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Profili Düzenle", style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          TextButton(
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
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Arka Plan Fotoğrafı
          Positioned.fill(
            bottom: 40,
            child: GestureDetector(
              onTap: () {}, // TODO: ImagePicker
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
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
            onTap: () {}, // TODO: ImagePicker
            child: CircleAvatar(
              radius: 55,
              backgroundColor: theme.scaffoldBackgroundColor,
              child: const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/icons/ic_profile.png'),
                child: Icon(Icons.add_a_photo, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    // API Call: PUT /api/Profile/me
    print("Kaydediliyor...");
    // İşlem bitince:
    setState(() => _isChanged = false);
  }
}
