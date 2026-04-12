import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:helmove/l10n/app_localizations.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_input_field.dart';
import 'package:helmove/features/content/posts/presentation/bloc/create_post_cubit.dart';
import 'package:helmove/features/content/posts/presentation/bloc/create_post_state.dart';
import 'package:helmove/features/content/posts/presentation/bloc/posts_bloc.dart';
import 'package:helmove/features/content/posts/presentation/bloc/posts_event.dart';

class PrepareMediaPage extends StatefulWidget {
  final File imageFile;

  const PrepareMediaPage({super.key, required this.imageFile});

  @override
  State<PrepareMediaPage> createState() => _PrepareMediaPageState();
}

class _PrepareMediaPageState extends State<PrepareMediaPage> {
  final TextEditingController _captionController = TextEditingController();
  late File _currentImageFile;

  @override
  void initState() {
    super.initState();
    _currentImageFile = widget.imageFile;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _submitPost(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final text = _captionController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseWriteSomething)),
      );
      return;
    }

    context.read<CreatePostCubit>().submitPost(
      text: text,
      visibility: 0,
      mediaUrl: _currentImageFile.path,
    );
  }

  Future<void> _cropImage() async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: _currentImageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Theme.of(context).colorScheme.surface,
          toolbarWidgetColor: Theme.of(context).colorScheme.onSurface,
          hideBottomControls: false,
          lockAspectRatio: false,
          aspectRatioPresets: const [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
          aspectRatioPresets: const [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );

    if (cropped == null || !mounted) return;
    setState(() {
      _currentImageFile = File(cropped.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox.shrink();
    }

    return BlocProvider(
      create: (context) => sl<CreatePostCubit>(),
      child: BlocListener<CreatePostCubit, CreatePostState>(
        listener: (context, state) {
          final loc = AppLocalizations.of(context);
          if (state.status == CreatePostStatus.success) {
            if (loc != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.postShared),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              );
            }
            sl<PostsBloc>().add(
              const GetFeedEvent(page: 1, limit: 10, isRefresh: true),
            );
            context.go('/homepage');
          } else if (state.status == CreatePostStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? loc?.unknownError ?? 'Error'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () => context.pop(),
            ),
            title: Text(
              l10n.new_post,
              style: AppTextStyles.h3.copyWith(color: colorScheme.onSurface),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 420,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: ColoredBox(
                              color: colorScheme.surfaceContainerHighest,
                              child: Image.file(
                                _currentImageFile,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _cropImage,
                            icon: const Icon(Icons.crop_rounded),
                            label: const Text('Adjust Crop'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.write_description,
                          style: AppTextStyles.medium.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AppInputField(
                          controller: _captionController,
                          minLines: 4,
                          maxLines: 6,
                          hint: l10n.write_description,
                          textInputAction: TextInputAction.newline,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: l10n.retake,
                          variant: AppButtonVariant.secondary,
                          style: AppButtonStyle.outlined,
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BlocBuilder<CreatePostCubit, CreatePostState>(
                          builder: (context, state) {
                            final isSubmitting =
                                state.status == CreatePostStatus.submitting;
                            return AppButton(
                              text: l10n.share,
                              variant: AppButtonVariant.primary,
                              style: AppButtonStyle.filled,
                              isLoading: isSubmitting,
                              onPressed: isSubmitting
                                  ? null
                                  : () => _submitPost(context),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
