
import 'package:flutter/material.dart';
import 'package:helmove/core/widgets/app_input_field.dart';

Widget buildInputReferencePage(BuildContext context) {
  return const InputReferencePage();
}

class InputReferencePage extends StatefulWidget {
  const InputReferencePage({super.key});

  @override
  State<InputReferencePage> createState() => _InputReferencePageState();
}

class _InputReferencePageState extends State<InputReferencePage> {
  // 1. Form Anahtarı (Validasyon testi için şart)
  final _formKey = GlobalKey<FormState>();

  // 2. Controller'lar
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _disabledController = TextEditingController(text: "Değiştirilemez Veri");

  @override
  void dispose() {
    // Hafıza sızıntısını önlemek için controller'ları kapat
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    _bioController.dispose();
    _disabledController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Input Referans Tablosu")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey, // Form anahtarını buraya veriyoruz
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              const Text("1. Login & Auth Senaryoları", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // --- E-MAIL (Validasyonlu) ---
              AppInputField(
                controller: _emailController,
                type: AppInputType.email,
                label: "E-Posta Adresi",
                hint: "motorcu@example.com",
                leadingIcon: Icons.email_outlined,
                validator: (val) {
                  if (val == null || val.isEmpty) return "E-posta boş bırakılamaz";
                  if (!val.contains("@")) return "Geçerli bir e-posta giriniz";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- PASSWORD (Otomatik Göz İkonlu) ---
              AppInputField(
                controller: _passwordController,
                type: AppInputType.password, // Bunu seçince göz ikonu otomatik gelir
                label: "Şifre",
                leadingIcon: Icons.lock_outline,
                validator: (val) {
                  if (val == null || val.length < 6) return "Şifre en az 6 karakter olmalı";
                  return null;
                },
              ),

              const Divider(height: 40),
              const Text("2. Profil Bilgileri", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // --- AD SOYAD (Otomatik Baş Harf Büyütme) ---
              Row(
                children: [
                  Expanded(
                    child: AppInputField(
                      controller: _nameController,
                      type: AppInputType.firstName,
                      label: "İsim",
                      size: AppInputSize.small, // Daha kompakt
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppInputField(
                      controller: TextEditingController(), // Örnek için inline
                      type: AppInputType.lastName,
                      label: "Soyisim",
                      size: AppInputSize.small,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- TELEFON (Sayısal Klavye) ---
              AppInputField(
                controller: _phoneController,
                type: AppInputType.phone,
                label: "Telefon Numarası",
                leadingIcon: Icons.phone_android,
                hint: "5XX XXX XX XX",
              ),
              
              const SizedBox(height: 16),

              // --- BIO / AÇIKLAMA (Çok Satırlı) ---
              AppInputField(
                controller: _bioController,
                type: AppInputType.standard,
                label: "Biyografi",
                hint: "Kendinden bahset...",
                maxLines: 4, // 4 satır yüksekliğinde kutu
                variant: AppInputVariant.outlined, // İçi boş, çizgili stil
              ),

              const Divider(height: 40),
              const Text("3. Aksiyon & Arama", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // --- ARAMA / KEŞFET (Temizleme Butonlu) ---
              AppInputField(
                controller: _searchController,
                type: AppInputType.discover,
                hint: "Grup veya kullanıcı ara...",
                leadingIcon: Icons.search,
                trailingIcon: Icons.cancel, // X ikonu
                onTrailingTap: () {
                  _searchController.clear(); // Tıklayınca yazıyı siler
                  debugPrint("Arama temizlendi");
                },
              ),

              const SizedBox(height: 16),

              // --- DISABLED (Pasif / Salt Okunur) ---
              AppInputField(
                controller: _disabledController,
                label: "Üye ID (Değişmez)",
                enabled: false, // Tıklanamaz, grileşir
                leadingIcon: Icons.fingerprint,
              ),

              const SizedBox(height: 30),

              // --- TEST BUTONU ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () {
                    // Formdaki tüm validator'ları tetikler
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Form Başarılı! Kaydediliyor...")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Hatalar var, lütfen kontrol edin."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text("Formu Test Et (Validasyon)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

