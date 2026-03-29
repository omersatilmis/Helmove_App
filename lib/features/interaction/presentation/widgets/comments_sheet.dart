import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/l10n/app_localizations.dart';
import '../../../../core/constants/report_enums.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../help/presentation/widgets/report_bottom_sheet.dart';
import '../../domain/entities/comment_entity.dart';
import '../bloc/comments_bloc.dart';
import '../bloc/comments_event.dart';
import '../bloc/comments_state.dart';
import '../../../../core/widgets/app_input_field.dart';

const int _commentsPageSize = 10;

class CommentsSheet extends StatefulWidget {
  final int contentId;

  const CommentsSheet({super.key, required this.contentId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  late final TextEditingController _commentController;
  late final FocusNode _commentFocusNode;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _commentFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _handleReply(String username) {
    setState(() {
      _commentController.text = '@$username ';
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    _commentFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // Klavye yüksekliğini dinlemek için
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return BlocProvider(
      create: (context) => sl<CommentsBloc>()
        ..add(
          LoadCommentsEvent(
            contentId: widget.contentId,
            page: 1,
            limit: _commentsPageSize,
          ),
        ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                // DİNAMİK ARKA PLAN RENGİ (Theme'den alır)
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const _SheetHeader(),
                  // Divider kaldırıldı, daha ferah bir görünüm için padding kullanıldı.

                  // Liste Alanı
                  Expanded(
                    child: _CommentsList(
                      scrollController: scrollController,
                      contentId: widget.contentId,
                      onReply: _handleReply,
                    ),
                  ),

                  // Input Alanı
                  _CommentInputArea(
                    contentId: widget.contentId,
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. HEADER WIDGET
// -----------------------------------------------------------------------------
class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsBloc, CommentsState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              // Gri Çubuk (Tutma yeri)
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.commentsTitle,
                    style: AppTextStyles.h3.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (state.comments.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        state.comments.length.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 2. LIST WIDGET
// -----------------------------------------------------------------------------
class _CommentsList extends StatelessWidget {
  final ScrollController scrollController;
  final int contentId;
  final Function(String) onReply;

  const _CommentsList({
    required this.scrollController,
    required this.contentId,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsBloc, CommentsState>(
      builder: (context, state) {
        // Yükleniyor...
        if (state.status == CommentsStatus.loading && state.comments.isEmpty) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        // Hata
        if (state.status == CommentsStatus.failure && state.comments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? AppLocalizations.of(context)!.errorOccurred,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        // Boş Liste
        if (state.comments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 60,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.noCommentsYet,
                  style: AppTextStyles.h3.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        // Dolu Liste (Infinite Scroll Logic)
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (!state.hasReachedMax &&
                state.status != CommentsStatus.loading &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent * 0.9) {
              context.read<CommentsBloc>().add(
                LoadCommentsEvent(
                  contentId: contentId,
                  page: state.currentPage + 1,
                  limit: _commentsPageSize,
                ),
              );
            }
            return true;
          },
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: state.hasReachedMax
                ? state.comments.length
                : state.comments.length + 1,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index >= state.comments.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator.adaptive(),
                  ),
                );
              }
              final comment = state.comments[index];
              return _CommentItem(
                comment: comment,
                contentId: contentId,
                onReply: onReply,
              );
            },
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 3. COMMENT ITEM
// -----------------------------------------------------------------------------
class _CommentItem extends StatelessWidget {
  final CommentEntity comment;
  final int contentId;
  final Function(String) onReply;

  const _CommentItem({
    required this.comment,
    required this.contentId,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gelişmiş AppAvatar Kullanımı
          AppAvatar(
            radius: 18,
            overrideImageUrl: comment.userAvatar,
            userId: comment.userId,
          ),
          const SizedBox(width: 12),

          // İçerik
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.username,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '•',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimeAgo(context, comment.createdAt),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 14,
                    height: 1.4,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                // Yanıtla Butonu (Artık Çalışıyor)
                GestureDetector(
                  onTap: () => onReply(comment.username),
                  child: Text(
                    AppLocalizations.of(context)!.reply,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Menü Butonu
          _CommentMoreButton(comment: comment, contentId: contentId),
        ],
      ),
    );
  }

  String _formatTimeAgo(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
    if (difference.inDays >= 1) return l10n.time_day_short(difference.inDays);
    if (difference.inHours >= 1) return l10n.time_hour_short(difference.inHours);
    if (difference.inMinutes >= 1) return l10n.time_minute_short(difference.inMinutes);
    return l10n.now;
  }
}

// -----------------------------------------------------------------------------
// 4. SAMSUNG STYLE MORE BUTTON (ADAM EDİLEN KISIM)
// -----------------------------------------------------------------------------
class _CommentMoreButton extends StatelessWidget {
  final CommentEntity comment;
  final int contentId;

  const _CommentMoreButton({required this.comment, required this.contentId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select(
      (CommentsBloc bloc) => bloc.state.currentUserId,
    );

    // ZIRHLI SAHİPLİK KONTROLÜ
    final bool isOwner =
        currentUserId != null &&
        currentUserId > 0 &&
        currentUserId == comment.userId;

    // SAMSUNG ONE UI STİLİ POPUP MENU
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded, // Dikey 3 nokta (daha modern)
        size: 18,
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant, // İkon rengi dinamik
      ),
      // Menü Arka Planı (Koyu tema için özel gri, açık tema için surface)
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF252525)
          : Theme.of(context).colorScheme.surfaceContainerHighest,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ), // Yuvarlak köşeler
      elevation: 4,
      offset: const Offset(0, 30), // Hafif aşağıdan açıl

      onSelected: (value) {
        if (value == 'delete') _showDeleteDialog(context);
        if (value == 'report') {
          ReportBottomSheet.show(
            context,
            targetId: comment.id.toString(),
            targetType: ReportTargetType.content,
          );
        }
      },
      itemBuilder: (context) => [
        if (isOwner)
          _buildPopupItem(
            context,
            'delete',
            Icons.delete_outline,
            AppLocalizations.of(context)!.delete,
            color: AppColors.error,
          ),
        if (!isOwner)
          _buildPopupItem(
            context,
            'report',
            Icons.report_gmailerrorred_rounded,
            AppLocalizations.of(context)!.report,
          ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    BuildContext context,
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    // Menüdeki yazı rengi (Arka plan koyuysa beyaz, açıksa siyah)
    final textColor = color ?? Theme.of(context).colorScheme.onSurface;

    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    // Bloc'u yakala
    final commentsBloc = context.read<CommentsBloc>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // Diyalog Arka Planı
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1C)
            : Theme.of(context).colorScheme.surface,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppLocalizations.of(context)!.delete_comment_title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              commentsBloc.add(
                DeleteCommentEvent(commentId: comment.id, contentId: contentId),
              );
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5. INPUT AREA
// -----------------------------------------------------------------------------
class _CommentInputArea extends StatefulWidget {
  final int contentId;
  final TextEditingController controller;
  final FocusNode focusNode;

  const _CommentInputArea({
    required this.contentId,
    required this.controller,
    required this.focusNode,
  });

  @override
  State<_CommentInputArea> createState() => _CommentInputAreaState();
}

class _CommentInputAreaState extends State<_CommentInputArea> {
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateComposing);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateComposing);
    super.dispose();
  }

  void _updateComposing() {
    final isNotEmpty = widget.controller.text.trim().isNotEmpty;
    if (_isComposing != isNotEmpty) {
      setState(() => _isComposing = isNotEmpty);
    }
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;

    context.read<CommentsBloc>().add(
      AddCommentEvent(contentId: widget.contentId, text: text),
    );
    widget.controller.clear();
    widget.focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Mevcut Kullanıcının Profil Fotoğrafı
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: AppAvatar(radius: 18, isCurrentUser: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppInputField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                minLines: 1,
                maxLines: 5,
                hint: AppLocalizations.of(context)!.add_comment_hint,
                radius: 24,
                size: AppInputSize.small,
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<CommentsBloc, CommentsState>(
              builder: (context, state) {
                if (state.isPostingComment) {
                  return const SizedBox(
                    width: 44,
                    height: 44,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return AnimatedOpacity(
                  opacity: _isComposing ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    iconSize: 28,
                    icon: Icon(
                      Icons.arrow_circle_up_rounded,
                      color: _isComposing
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: _isComposing ? _submit : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
