// motor ekleme alanı için düzenlenmiş widget

import 'package:flutter/material.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/features/profile/domain/entities/motorcycle_entity.dart';
import 'package:provider/provider.dart';
import 'package:helmove/features/profile/presentation/providers/profile_provider.dart';
import 'package:helmove/core/widgets/app_input_field.dart';

class BikeCardWidget extends StatefulWidget {
  final MotorcycleEntity bike;
  final VoidCallback?
  onDelete; // Opsiyonel yaptık, provider üzerinden de silinebilir
  final VoidCallback? onSave; // 🔥 Kayıt başarılı olduğunda çağrılır
  final bool initialEdit;

  const BikeCardWidget({
    super.key,
    required this.bike,
    this.onDelete,
    this.onSave,
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

    _makeModelCtrl = TextEditingController(
      text: "${widget.bike.brand} ${widget.bike.model}".trim(),
    );
    _ccCtrl = TextEditingController(
      text: widget.bike.engineSize?.toString() ?? "",
    );
    _yearCtrl = TextEditingController(text: widget.bike.year?.toString() ?? "");
    _colorCtrl = TextEditingController(text: widget.bike.color ?? "");
    _plateCtrl = TextEditingController(text: widget.bike.licensePlate ?? "");
    _descCtrl = TextEditingController(text: widget.bike.description ?? "");
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

  Future<void> _save() async {
    final provider = context.read<ProfileProvider>();
    final parts = _makeModelCtrl.text.trim().split(' ');
    final brand = parts.isNotEmpty ? parts[0] : "";
    final model = parts.length > 1 ? parts.sublist(1).join(' ') : "";

    final engineSize = int.tryParse(_ccCtrl.text.trim());
    final year = int.tryParse(_yearCtrl.text.trim());

    bool success = false;

    if (widget.bike.id != null) {
      // Güncelleme
      success = await provider.updateMotorcycle(
        motorcycleId: widget.bike.id!,
        brand: brand,
        model: model,
        year: year,
        licensePlate: _plateCtrl.text.trim(),
        color: _colorCtrl.text.trim(),
        engineSize: engineSize,
        description: _descCtrl.text.trim(),
        isPrimary: widget.bike.isPrimary,
      );
    } else {
      // Yeni Ekleme (ID yoksa)
      // Ancak buradaki widget genellikle listede gösterilir.
      // Eğer "yeni ekle" butonu boş bir kart açıyorsa burası çalışır.
      // Fakat genelde Add butonu direkt provider.addMotorcycle ile ekleyip
      // sonra listeyi yenileyeceği için buraya gerek kalmayabilir.
      // Yine de mantığı kuralım:
      success = await provider.addMotorcycle(
        brand: brand,
        model: model,
        year: year,
        licensePlate: _plateCtrl.text.trim(),
        color: _colorCtrl.text.trim(),
        engineSize: engineSize,
        description: _descCtrl.text.trim(),
        isPrimary: widget.bike.isPrimary,
      );
    }

    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      widget.onSave?.call(); // 🔥 Kayıt başarılı callback
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Motosiklet kaydedildi")));
    }
  }

  void _cancel() {
    // Eğer yeni eklenmeye çalışılan (ID'si olmayan) bir motorsa ve iptal edildiyse
    // listeden kaldırılmalı (parent widget bunu yönetmeli veya providerdan silinmeli).
    // Burada basitçe edit modundan çıkıyoruz.
    if (widget.bike.id == null) {
      widget.onDelete?.call();
      return;
    }

    setState(() {
      _makeModelCtrl.text = widget.bike.fullName;
      _ccCtrl.text = widget.bike.engineSize?.toString() ?? "";
      _yearCtrl.text = widget.bike.year?.toString() ?? "";
      _colorCtrl.text = widget.bike.color ?? "";
      _plateCtrl.text = widget.bike.licensePlate ?? "";
      _descCtrl.text = widget.bike.description ?? "";
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor.withValues(alpha:0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
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
                  onPressed: () async {
                    // Favori (Primary) yapma işlemi
                    if (widget.bike.id != null) {
                      await context
                          .read<ProfileProvider>()
                          .setPrimaryMotorcycle(widget.bike.id!);
                    }
                  },
                  icon: Icon(
                    widget.bike.isPrimary
                        ? Icons
                              .star_rounded // Favori için yıldız daha uygun
                        : Icons.star_border_rounded,
                    color: widget.bike.isPrimary
                        ? Colors
                              .amber // Favori rengi
                        : theme.colorScheme.onSurface.withValues(alpha:0.3),
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
          onPressed: () async {
            if (widget.bike.id != null) {
              await context.read<ProfileProvider>().deleteMotorcycle(
                widget.bike.id!,
              );
            } else {
              widget.onDelete?.call();
            }
          },
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
      color: theme.colorScheme.onSurface.withValues(alpha:0.5),
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
          widget.bike.fullName,
          labelStyle,
          valueStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _infoRow(
                "CC",
                widget.bike.engineSizeFormatted,
                labelStyle,
                valueStyle,
              ),
            ),
            Expanded(
              child: _infoRow(
                "Yıl",
                widget.bike.year?.toString() ?? "-",
                labelStyle,
                valueStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _infoRow(
                "Renk",
                widget.bike.color ?? "-",
                labelStyle,
                valueStyle,
              ),
            ),
            Expanded(
              child: _infoRow(
                "Plaka",
                widget.bike.licensePlate ?? "-",
                labelStyle,
                valueStyle,
              ),
            ),
          ],
        ),
        if (widget.bike.description != null &&
            widget.bike.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text("Açıklama", style: labelStyle),
          const SizedBox(height: 4),
          Text(
            widget.bike.description!,
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
            Expanded(
              child: _editField(
                theme,
                "CC",
                _ccCtrl,
                isNumber: true,
                hint: "xxxx",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _editField(
                theme,
                "Yıl",
                _yearCtrl,
                isNumber: true,
                hint: "xxxx",
              ),
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
    String? hint,
  }) {
    return AppInputField(
      controller: ctrl,
      label: label,
      hint: hint,
      maxLines: maxLines,
      type: isNumber
          ? AppInputType.phone
          : AppInputType.standard, // phone klavyesi sayısal için iş görür
    );
  }
}
