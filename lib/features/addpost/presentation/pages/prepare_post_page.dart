import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/text_styles.dart';
import 'package:moto_comm_app_1/features/content/posts/presentation/bloc/create_post_cubit.dart';
import 'package:moto_comm_app_1/features/content/posts/presentation/bloc/create_post_state.dart';

class PreparePostPage extends StatefulWidget {
  final File imageFile;

  const PreparePostPage({super.key, required this.imageFile});

  @override
  State<PreparePostPage> createState() => _PreparePostPageState();
}

class _PreparePostPageState extends State<PreparePostPage> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CreatePostCubit>(),
      child: BlocListener<CreatePostCubit, CreatePostState>(
        listener: (context, state) {
          if (state.status == CreatePostStatus.success) {
            context.go('/homepage');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gönderi paylaşıldı!'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state.status == CreatePostStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Bir hata oluştu'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.darkBackground,
          appBar: AppBar(
            backgroundColor: AppColors.darkBackground,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.darkTextPrimary,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text('Yeni Gönderi', style: AppTextStyles.h3),
            actions: [
              BlocBuilder<CreatePostCubit, CreatePostState>(
                builder: (context, state) {
                  return TextButton(
                    onPressed: state.status == CreatePostStatus.submitting
                        ? null
                        : () {
                            // Gönderiyi paylaş
                            context.read<CreatePostCubit>().submitPost(
                              text: _captionController.text,
                              visibility: 0, // Public
                              mediaUrl: widget
                                  .imageFile
                                  .path, // Şimdilik path gönderiyoruz, backend upload lazım
                            );
                          },
                    child: state.status == CreatePostStatus.submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Paylaş',
                            style: AppTextStyles.bold.copyWith(
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sol: Küçük Resim
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(widget.imageFile),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Sağ: Açıklama Alanı
                    Expanded(
                      child: TextField(
                        controller: _captionController,
                        maxLines: 4,
                        style: AppTextStyles.medium.copyWith(
                          color: AppColors.darkTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Bir açıklama yaz...',
                          hintStyle: AppTextStyles.medium.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(
                  color: AppColors.darkSurfaceContainer,
                  height: 32,
                ),

                // Ekstralar (Konum vb. eklenebilir - Şimdilik sadece placeholder)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.darkTextSecondary,
                  ),
                  title: Text(
                    'Konum Ekle',
                    style: AppTextStyles.medium.copyWith(
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.darkTextSecondary,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
