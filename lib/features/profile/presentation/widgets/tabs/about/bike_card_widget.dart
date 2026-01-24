// motor ekleme alanı için düzenlenmiş widget

import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/features/profile/presentation/widgets/tabs/about/bike_model.dart';

// bike_model.dart : backende bağlayınca bunu sil, gerçek modelle değiştir, importunu üste ekle bike_card_widgette de var bundan

class BikeCardWidget extends StatefulWidget {
  final BikeModel bike;
  final VoidCallback onDelete;
  final bool initialEdit; // Yeni eklendiğinde direkt edit modunda açılması için

  const BikeCardWidget({
    super.key,
    required this.bike,
    required this.onDelete,
    this.initialEdit = false,
  });

  @override
  State<BikeCardWidget> createState() => _BikeCardWidgetState();
}

class _BikeCardWidgetState extends State<BikeCardWidget> {
  late bool _isEditing;

  // Form alanları için controllerlar
  late TextEditingController _makeModelCtrl;
  late TextEditingController _ccCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _plateCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialEdit;

    _makeModelCtrl = TextEditingController(text: widget.bike.makeModel);
    _ccCtrl = TextEditingController(text: widget.bike.cc);
    _yearCtrl = TextEditingController(text: widget.bike.year);
    _colorCtrl = TextEditingController(text: widget.bike.color);
    _plateCtrl = TextEditingController(text: widget.bike.plate);
    _descCtrl = TextEditingController(text: widget.bike.description);
  }

  @override
  void dispose() {
    _makeModelCtrl.dispose();
    _ccCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _plateCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    setState(() {
      widget.bike.makeModel = _makeModelCtrl.text;
      widget.bike.cc = _ccCtrl.text;
      widget.bike.year = _yearCtrl.text;
      widget.bike.color = _colorCtrl.text;
      widget.bike.plate = _plateCtrl.text;
      widget.bike.description = _descCtrl.text;
      _isEditing = false;
    });
  }

  void _cancel() {
    // Eğer motor yeni eklenmişse (ismi yoksa) ve iptal edildiyse, kartı tamamen sil
    if (widget.bike.makeModel.isEmpty && _makeModelCtrl.text.isEmpty) {
      widget.onDelete();
      return;
    }

    setState(() {
      _makeModelCtrl.text = widget.bike.makeModel;
      _ccCtrl.text = widget.bike.cc;
      _yearCtrl.text = widget.bike.year;
      _colorCtrl.text = widget.bike.color;
      _plateCtrl.text = widget.bike.plate;
      _descCtrl.text = widget.bike.description;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- ÜST PANEL (İkonlar) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // FAVORİ BUTONU
                IconButton(
                  onPressed: () => setState(
                    () => widget.bike.isFavorite = !widget.bike.isFavorite,
                  ),
                  icon: Icon(
                    widget.bike.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: widget.bike.isFavorite
                        ? Colors.redAccent
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                // AKSİYON BUTONLARI
                _isEditing
                    ? _buildEditActions(theme)
                    : _buildViewActions(theme),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- İÇERİK ALANI ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isEditing ? _buildEditForm(theme) : _buildViewInfo(theme),
            ),
          ),
        ],
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  Widget _buildViewActions(ThemeData theme) {
    return IconButton(
      onPressed: () => setState(() => _isEditing = true),
      icon: Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
    );
  }

  Widget _buildEditActions(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: widget.onDelete,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
          ),
        ),
        IconButton(
          onPressed: _cancel,
          icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
        ),
        IconButton(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildViewInfo(ThemeData theme) {
    final labelStyle = AppTextStyles.bodySmall.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      fontSize: 12,
    );
    final valueStyle = AppTextStyles.medium.copyWith(
      color: theme.colorScheme.onSurface,
      fontSize: 15,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(
          "Marka ve Model",
          widget.bike.makeModel,
          labelStyle,
          valueStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _infoRow("CC", widget.bike.cc, labelStyle, valueStyle),
            ),
            Expanded(
              child: _infoRow("Yıl", widget.bike.year, labelStyle, valueStyle),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _infoRow(
                "Renk",
                widget.bike.color,
                labelStyle,
                valueStyle,
              ),
            ),
            Expanded(
              child: _infoRow(
                "Plaka",
                widget.bike.plate,
                labelStyle,
                valueStyle,
              ),
            ),
          ],
        ),
        if (widget.bike.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text("Açıklama", style: labelStyle),
          const SizedBox(height: 4),
          Text(
            widget.bike.description,
            style: AppTextStyles.thin.copyWith(fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(
    String label,
    String value,
    TextStyle lStyle,
    TextStyle vStyle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: lStyle),
        Text(value.isEmpty ? "-" : value, style: vStyle),
      ],
    );
  }

  Widget _buildEditForm(ThemeData theme) {
    return Column(
      children: [
        _editField(theme, "Marka ve Model", _makeModelCtrl),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _editField(theme, "CC", _ccCtrl, isNumber: true)),
            const SizedBox(width: 10),
            Expanded(
              child: _editField(theme, "Yıl", _yearCtrl, isNumber: true),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _editField(theme, "Renk", _colorCtrl)),
            const SizedBox(width: 10),
            Expanded(child: _editField(theme, "Plaka", _plateCtrl)),
          ],
        ),
        const SizedBox(height: 10),
        _editField(theme, "Açıklama", _descCtrl, maxLines: 3),
      ],
    );
  }

  Widget _editField(
    ThemeData theme,
    String label,
    TextEditingController ctrl, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
