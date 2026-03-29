import 'package:flutter/material.dart';
import 'package:helmove/core/widgets/app_input_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/core/theme/app_colors.dart';
import 'package:helmove/core/di/injection_container.dart';
import 'package:helmove/core/constants/feedback_enums.dart';
import 'package:helmove/features/help/presentation/bloc/help_bloc.dart';
import 'package:helmove/features/help/presentation/bloc/help_event.dart';
import 'package:helmove/features/help/presentation/bloc/help_state.dart';
import 'package:helmove/features/help/domain/entities/feedback_entity.dart';
import 'package:helmove/l10n/app_localizations.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  FeedbackCategory _selectedCategory = FeedbackCategory.general;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  void _submitFeedback(BuildContext context) {
    FocusScope.of(context).unfocus();
    final title = _titleController.text.trim();
    final message = _controller.text.trim();
    final l10n = AppLocalizations.of(context)!;
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.validationTitle)),
      );
      return;
    }
    
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.validationMessage)),
      );
      return;
    }

    context.read<HelpBloc>().add(
          SendFeedbackEvent(
            FeedbackEntity(
              category: _selectedCategory,
              title: title,
              content: message,
              status: FeedbackStatus.newStatus,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => sl<HelpBloc>(),
      child: BlocListener<HelpBloc, HelpState>(
        listener: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          if (state.status == HelpStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.feedbackSuccess)),
            );
            Navigator.pop(context);
          } else if (state.status == HelpStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.feedbackError(state.errorMessage ?? l10n.unknownError)),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)!.sendFeedback,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(context, isDark),
                const SizedBox(height: 32),

                _buildSectionTitle(AppLocalizations.of(context)!.selectCategory, isDark),
                const SizedBox(height: 16),
                _buildCategorySelector(context, isDark),

                const SizedBox(height: 32),
                _buildSectionTitle(AppLocalizations.of(context)!.writeTitle, isDark),
                const SizedBox(height: 16),
                _buildTitleField(context, isDark),

                const SizedBox(height: 32),
                _buildSectionTitle(AppLocalizations.of(context)!.writeMessage, isDark),
                const SizedBox(height: 16),
                _buildMessageField(context, isDark),

                const SizedBox(height: 40),
                _buildSubmitButton(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.feedbackInfo,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: FeedbackCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? category.color
                  : (isDark ? AppColors.darkSurface : Colors.white),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? category.color
                    : (isDark ? Colors.white12 : Colors.black12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category.icon,
                  size: 18,
                  color: isSelected ? Colors.white : category.color,
                ),
                const SizedBox(width: 8),
                Text(
                  category.localizedLabel(l10n),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextPrimary.withValues(alpha: 0.7)
                            : AppColors.lightTextPrimary.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTitleField(BuildContext context, bool isDark) {
    return AppInputField(
      controller: _titleController,
      hint: AppLocalizations.of(context)!.writeTitleHint,
    );
  }

  Widget _buildMessageField(BuildContext context, bool isDark) {
    return AppInputField(
      controller: _controller,
      maxLines: 6,
      minLines: 3,
      hint: AppLocalizations.of(context)!.writeMessageHint,
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return BlocBuilder<HelpBloc, HelpState>(
      builder: (context, state) {
        final isLoading = state.status == HelpStatus.loading;
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : () => _submitFeedback(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.send,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        );
      },
    );
  }
}
