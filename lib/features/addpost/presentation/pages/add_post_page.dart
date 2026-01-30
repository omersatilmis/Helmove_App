import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickImage();
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        if (mounted) {
          // PushReplacement çünkü geri gelince tekrar kamerayı açmaya çalışabilir veya boş kalabilir.
          // Ama kullanıcı "Geri" deyince tekrar kamerayı çekmek isteyebilir.
          // O yüzden pushReplacement kullanıp, AddPostPage'in tekrar mount olunca kamerasını açmasını sağlayabiliriz.
          // Ancak AddPostPage stack'te kalırsa, geri dönünce tekrar initState çalışmaz (stateful).
          // Stack yapısı: Home -> AddPost (Camera) -> PreparePost
          // PreparePost'tan geri gelince -> AddPost (Camera)
          // AddPost'tan geri gelince -> Home

          // O yüzden pushReplacement yaparsak: Home -> PreparePost
          // PreparePost'tan geri gelince -> Home (Kişi fotoyu iptal edip tekrar çekmek isterse ne olacak?)

          // En iyisi: pushReplacement. Eğer kişi fotoyu beğenmezse, PreparePost'a bir "iptal/geri" butonu koyduk zaten (AppBar back).
          // O back butonu bizi Home'a atar. Bu kötü.

          // Şöyle yapalım:
          // AddPostPage sadece bir launcher.
          // Foto çekildi -> PreparePost'a git (Replacement ile).
          // PreparePost'ta "Geri" tuşu -> Tekrar AddPost'a git (Replacement ile).

          // Veya daha basiti:
          // AddPostPage kalsın. PreparePost'a push yapalım.
          // PreparePost'tan geri gelince AddPostPage görünür.
          // AddPostPage görünür olunca ne yapacak?
          // Şu anki kodda bir şey yapmaz, öylece boş durur (loader var).

          // Çözüm: then() bloğu ile geri dönüşü yakala ve tekrar _pickImage çağır.

          File file = File(pickedFile.path);
          context.push('/prepare_post', extra: file).then((_) {
            // Geri dönüldüğünde tekrar kamerayı aç
            if (mounted) _pickImage();
          });
        }
      } else {
        // Kullanıcı iptal ettiyse sayfayı kapat
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        Navigator.pop(context); // Hata durumunda da çık
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera erişiminde hata oluştu')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text('Paylaşım Yap', style: AppTextStyles.h3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // Using automatic leading or custom if needed.
        // Since it's in a shell route but likely accessed via bottom bar,
        // standard back button might not be present if it's a top level branch.
        // But if we want to allow going back or canceling, we might need a distinct UI.
        // However, bottom bar items usually are top-level.
        // Let's keep it simple.
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_imageFile != null) ...[
              // Image Preview
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Tekrar Çek',
                      variant: AppButtonVariant.secondary,
                      onPressed: _pickImage,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      text: 'Devam Et',
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        // TODO: Navigate to editing/caption page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sonraki aşama henüz eklenmedi'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Kamera açılırken veya yüklenirken boş ekran (veya loader)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
