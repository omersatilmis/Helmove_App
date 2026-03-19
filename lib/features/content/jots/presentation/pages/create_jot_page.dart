import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/core/theme/app_colors.dart';
import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:moto_comm_app_1/features/content/jots/presentation/bloc/jots_bloc.dart';
import 'package:moto_comm_app_1/features/content/jots/presentation/bloc/jots_event.dart';
import 'package:moto_comm_app_1/features/content/jots/presentation/bloc/jots_state.dart';
import 'package:moto_comm_app_1/features/content/jots/domain/entities/jot_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateJotsPage extends StatefulWidget {
  const CreateJotsPage({super.key});

  @override
  State<CreateJotsPage> createState() => _CreateJotsPageState();
}

class _CreateJotsPageState extends State<CreateJotsPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final ValueNotifier<bool> _canPostNotifier = ValueNotifier(false);
  final ValueNotifier<int> _charCountNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  void _onTextChanged() {
    final length = _controller.text.length;
    final canPost =
        (_controller.text.trim().isNotEmpty || _selectedImage != null) &&
        length <= 280;

    if (_charCountNotifier.value != length) {
      _charCountNotifier.value = length;
    }
    if (_canPostNotifier.value != canPost) {
      _canPostNotifier.value = canPost;
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Görsel Ekle",
              style: AppTextStyles.h3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        setState(() {
                          _selectedImage = File(image.path);
                          _onTextChanged();
                        });
                      }
                    },
                    child: Column(
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          color: AppColors.primary,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Fotoğraf Çek",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        setState(() {
                          _selectedImage = File(image.path);
                          _onTextChanged();
                        });
                      }
                    },
                    child: Column(
                      children: [
                        const Icon(
                          Icons.photo_library,
                          color: AppColors.primary,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Galeriden Seç",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _canPostNotifier.dispose();
    _charCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface, size: 22),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: BlocConsumer<JotsBloc, JotsState>(
              listener: (context, state) {
                if (state.createStatus == JotsStatus.success) {
                  if (!context.mounted) return;
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Jot paylaşıldı!')),
                  );
                } else if (state.createStatus == JotsStatus.failure) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.createError.isNotEmpty ? state.createError : 'Hata oluştu')),
                  );
                }
              },
              builder: (context, state) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _canPostNotifier,
                  builder: (context, canPost, child) {
                    final isLoading = state.createStatus == JotsStatus.loading;

                    return ElevatedButton(
                      onPressed: (canPost && !isLoading)
                          ? () {
                              context.read<JotsBloc>().add(
                                CreateJotEvent(
                                  type: _selectedImage != null
                                      ? JotType.image
                                      : JotType.text,
                                  text: _controller.text.trim(),
                                  mediaUrl: _selectedImage?.path,
                                  visibility: JotVisibility.public,
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: theme.colorScheme.primary
                            .withValues(alpha: 0.5),
                        disabledForegroundColor: Colors.white.withValues(
                          alpha: 0.5,
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Jotla",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst Kısım: Profil Fotoğrafı ve İsimler
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage:
                            (user?.profileImageUrl != null &&
                                user!.profileImageUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(user.profileImageUrl!)
                            : const AssetImage('assets/icons/ic_profile.png')
                                  as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? "Sürücü",
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            "@${user?.username ?? 'username'}",
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Alt Kısım: Metin Yazma Alanı (Sola Yaslı, PP Altından Başlıyor)
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: null,
                    maxLength: 280,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 18,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface,
                    ),
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => const SizedBox.shrink(),
                    decoration: InputDecoration(
                      hintText: "Bugün ne paylaşmak istersin?",
                      filled: false, // Arka plan rengini tamamen kapattım
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      hintStyle: TextStyle(
                        fontSize: 18,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  if (_selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedImage = null;
                                  _onTextChanged();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          /// BOTTOM TOOLBAR
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 16,
              top: 8,
              left: 12,
              right: 16,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              children: [
                _toolIcon(Icons.image_outlined, theme, onPressed: _pickImage),
                _toolIcon(Icons.format_list_bulleted_rounded, theme),
                _toolIcon(Icons.location_on_outlined, theme),
                _toolIcon(Icons.sentiment_satisfied_alt_outlined, theme),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: _charCountNotifier,
                  builder: (context, count, child) {
                    final progress = count / 280;
                    final isNearLimit = count > 250;

                    return Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 4),
                      child: CircularProgressIndicator(
                        value: progress > 1.0 ? 1.0 : progress,
                        strokeWidth: 2,
                        backgroundColor: theme.dividerColor.withValues(
                          alpha: 0.1,
                        ),
                        color: count > 280
                            ? Colors.red
                            : isNearLimit
                            ? Colors.orange
                            : theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolIcon(IconData icon, ThemeData theme, {VoidCallback? onPressed}) {
    return IconButton(
      onPressed: onPressed ?? () {},
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(10),
      icon: Icon(icon, color: theme.colorScheme.primary, size: 22),
    );
  }
}
