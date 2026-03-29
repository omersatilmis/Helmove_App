import 'package:flutter/material.dart';
import 'package:helmove/core/widgets/app_input_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/l10n/app_localizations.dart';
import '../../../../core/constants/report_enums.dart';
import '../../domain/entities/report_entity.dart';
import '../bloc/help_bloc.dart';
import '../bloc/help_event.dart';
import '../bloc/help_state.dart';

class ReportBottomSheet extends StatefulWidget {
  final String targetId;
  final ReportTargetType targetType;

  const ReportBottomSheet({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  static Future<void> show(
    BuildContext context, {
    required String targetId,
    required ReportTargetType targetType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportBottomSheet(
        targetId: targetId,
        targetType: targetType,
      ),
    );
  }

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  ReportCategory _selectedCategory = ReportCategory.spam;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<HelpBloc, HelpState>(
      listener: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        if (state.status == HelpStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage ?? l10n.reportSuccess),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state.status == HelpStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? l10n.reportError),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Row(
              children: [
                Icon(widget.targetType.icon, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.reportDetailed(widget.targetType.label),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.reportDescription,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Category Selection
            Text(
              AppLocalizations.of(context)!.selectReason,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ReportCategory>(
                  value: _selectedCategory,
                  dropdownColor: const Color(0xFF252525),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                  items: ReportCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(category.icon, color: category.color, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            category.label,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedCategory = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              AppLocalizations.of(context)!.additionalInfo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            AppInputField(
              controller: _descriptionController,
              maxLines: 3,
              hint: AppLocalizations.of(context)!.explainSituation,
              radius: 16,
            ),
            const SizedBox(height: 32),

            // Submit Button
            BlocBuilder<HelpBloc, HelpState>(
              builder: (context, state) {
                final isLoading = state.status == HelpStatus.loading;

                return ElevatedButton(
                  onPressed: isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3040),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.sendReport,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitReport() {
    final report = ReportEntity(
      targetId: widget.targetId,
      targetType: widget.targetType,
      category: _selectedCategory,
      description: _descriptionController.text.trim().isEmpty
          ? 'Kategori: ${_selectedCategory.label}'
          : _descriptionController.text.trim(),
      status: ReportStatus.pending,
    );

    context.read<HelpBloc>().add(CreateReportEvent(report));
  }
}
