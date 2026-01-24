// About kısmı için düzenlenmiş widget

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/text_styles.dart';

class AboutSection extends StatefulWidget {
  const AboutSection({super.key});

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  String _aboutText = "Merhaba! Ben Marcus. Flutter ile mobil uygulamalar geliştirmeyi seviyorum.";
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _aboutText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("About Me", style: AppTextStyles.h3.copyWith(fontSize: 18, color: theme.colorScheme.onSurface)),
            _isEditing ? _buildEditActions() : _buildViewActions(theme),
          ],
        ),
        const SizedBox(height: 12),
        _isEditing ? _buildEditField(theme) : _buildViewText(theme),
      ],
    );
  }

  Widget _buildViewActions(ThemeData theme) {
    return IconButton(
      onPressed: () => setState(() => _isEditing = true),
      icon: Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        IconButton(onPressed: _deleteAbout, icon: const Icon(Icons.delete_rounded, color: Colors.redAccent)),
        IconButton(onPressed: () => setState(() => _isEditing = false), icon: const Icon(Icons.close_rounded)),
        IconButton(onPressed: _saveAbout, icon: const Icon(Icons.check_rounded, color: Colors.green)),
      ],
    );
  }

  void _saveAbout() {
    setState(() {
      _aboutText = _controller.text;
      _isEditing = false;
    });
  }

  void _deleteAbout() {
    setState(() {
      _controller.clear();
      _aboutText = "";
      _isEditing = false;
    });
  }

  Widget _buildViewText(ThemeData theme) {
    return Text(_aboutText.isEmpty ? "Henüz bilgi girilmemiş." : _aboutText,
        style: AppTextStyles.thin.copyWith(fontSize: 15, height: 1.5));
  }

  Widget _buildEditField(ThemeData theme) {
    return TextField(
      controller: _controller,
      maxLines: null,
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}