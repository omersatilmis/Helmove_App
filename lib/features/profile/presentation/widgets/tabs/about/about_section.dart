// About kısmı için düzenlenmiş widget

import 'package:flutter/material.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:provider/provider.dart';
import 'package:helmove/features/profile/presentation/providers/profile_provider.dart';
import 'package:helmove/core/widgets/app_input_field.dart';
import 'package:helmove/l10n/app_localizations.dart';

class AboutSection extends StatefulWidget {
  final bool isOwnProfile;

  const AboutSection({super.key, required this.isOwnProfile});

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AboutSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isOwnProfile && _isEditing) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ProfileProvider>();
    final bio = widget.isOwnProfile
        ? (provider.profile?.bio ?? "")
        : (provider.visitedProfile?.bio ?? "");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.aboutMe,
              style: AppTextStyles.h3.copyWith(
                fontSize: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
            _isEditing
                ? _buildEditActions()
                : _buildViewActions(
                    theme,
                    bio,
                    isOwnProfile: widget.isOwnProfile,
                  ), // bio'yu parametre olarak geçelim
          ],
        ),
        const SizedBox(height: 12),
        _isEditing ? _buildEditField(theme) : _buildViewText(theme, bio),
      ],
    );
  }

  Widget _buildViewActions(
    ThemeData theme,
    String currentBio, {
    required bool isOwnProfile,
  }) {
    if (!isOwnProfile) return const SizedBox.shrink();

    return IconButton(
      onPressed: () {
        setState(() {
          _isEditing = true;
          _controller.text =
              currentBio; // Düzenlemeye başlarken mevcut bio'yu kopyala
        });
      },
      icon: Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        IconButton(
          onPressed: _deleteAbout,
          icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
        ),
        IconButton(
          onPressed: () => setState(() => _isEditing = false),
          icon: const Icon(Icons.close_rounded),
        ),
        IconButton(
          onPressed: _saveAbout,
          icon: const Icon(Icons.check_rounded, color: Colors.green),
        ),
      ],
    );
  }

  Future<void> _saveAbout() async {
    if (!widget.isOwnProfile) return;

    final provider = context.read<ProfileProvider>();
    final success = await provider.updateProfile(bio: _controller.text.trim());

    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hakkında bilgisi güncellendi")),
      );
    }
  }

  Future<void> _deleteAbout() async {
    if (!widget.isOwnProfile) return;

    final provider = context.read<ProfileProvider>();
    final success = await provider.updateProfile(bio: "");

    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Hakkında bilgisi silindi")));
    }
  }

  Widget _buildViewText(ThemeData theme, String bio) {
    return Text(
      bio.isEmpty ? "Henüz bilgi girilmemiş." : bio,
      style: AppTextStyles.thin.copyWith(fontSize: 15, height: 1.5),
    );
  }

  Widget _buildEditField(ThemeData theme) {
    return AppInputField(
      controller: _controller,
      maxLines: null,
      minLines: 3,
      hint: "Kendinizden bahsedin...",
    );
  }
}
