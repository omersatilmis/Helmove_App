import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../../domain/entities/comment_entity.dart';
import '../bloc/comments_bloc.dart';
import '../bloc/comments_event.dart';
import '../bloc/comments_state.dart';

class CommentsSheet extends StatelessWidget {
  final int contentId;

  const CommentsSheet({super.key, required this.contentId});

  @override
  Widget build(BuildContext context) {
    // Klavye yüksekliğini dinlemek için
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return BlocProvider(
      create: (context) =>
          sl<CommentsBloc>()..add(LoadCommentsEvent(contentId: contentId)),
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
                  Divider(height: 1, color: Theme.of(context).dividerColor),

                  // Liste Alanı
                  Expanded(
                    child: _CommentsList(
                      scrollController: scrollController,
                      contentId: contentId,
                    ),
                  ),

                  // Input Alanı
                  _CommentInputArea(contentId: contentId),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // Gri Çubuk (Tutma yeri)
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              // DİNAMİK RENK: Arka plan koyuysa açık, açıksa koyu olur
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Yorumlar',
            // DİNAMİK TEXT STİLİ
            style: AppTextStyles.h3.copyWith(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. LIST WIDGET
// -----------------------------------------------------------------------------
class _CommentsList extends StatelessWidget {
  final ScrollController scrollController;
  final int contentId;

  const _CommentsList({
    required this.scrollController,
    required this.contentId,
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
                  state.errorMessage ?? 'Hata oluştu',
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
                  'Henüz yorum yok.',
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
              return _CommentItem(comment: comment, contentId: contentId);
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

  const _CommentItem({required this.comment, required this.contentId});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          backgroundImage:
              comment.userAvatar != null && comment.userAvatar!.isNotEmpty
              ? CachedNetworkImageProvider(comment.userAvatar!)
              : null,
          child: (comment.userAvatar == null || comment.userAvatar!.isEmpty)
              ? Text(
                  comment.username.isNotEmpty
                      ? comment.username[0].toUpperCase()
                      : "?",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),

        // İçerik
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.username,
                    // DİNAMİK TEXT RENGİ
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimeAgo(comment.createdAt),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                comment.text,
                // DİNAMİK TEXT RENGİ
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 14,
                  height: 1.3,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),

        // SAMSUNG STYLE MENÜ BUTONU (Burada)
        _CommentMoreButton(comment: comment, contentId: contentId),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
    if (difference.inDays >= 1) return "${difference.inDays}g";
    if (difference.inHours >= 1) return "${difference.inHours}sa";
    if (difference.inMinutes >= 1) return "${difference.inMinutes}dk";
    return "Şimdi";
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
        currentUserId != 0 &&
        currentUserId.toString() == comment.userId.toString();

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Şikayetiniz iletildi.')),
          );
        }
      },
      itemBuilder: (context) => [
        if (isOwner)
          _buildPopupItem(
            context,
            'delete',
            Icons.delete_outline,
            'Sil',
            color: AppColors.error,
          ),
        if (!isOwner)
          _buildPopupItem(
            context,
            'report',
            Icons.report_gmailerrorred_rounded,
            'Şikayet Et',
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
          'Yorumu Sil?',
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
              'İptal',
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
            child: const Text(
              'Sil',
              style: TextStyle(
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

  const _CommentInputArea({required this.contentId});

  @override
  State<_CommentInputArea> createState() => _CommentInputAreaState();
}

class _CommentInputAreaState extends State<_CommentInputArea> {
  final TextEditingController _controller = TextEditingController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final isNotEmpty = _controller.text.trim().isNotEmpty;
      if (_isComposing != isNotEmpty) {
        setState(() => _isComposing = isNotEmpty);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    context.read<CommentsBloc>().add(
      AddCommentEvent(contentId: widget.contentId, text: text),
    );
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, // Dinamik zemin
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: AppInputField(
                controller: _controller,
                hint: 'Yorum ekle...',
                minLines: 1,
                maxLines: 4,
                radius: 24,
                // AppInputField senin temanı kullanacak şekilde zaten ayarlıdır
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<CommentsBloc, CommentsState>(
              builder: (context, state) {
                if (state.isPostingComment) {
                  return const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: _isComposing
                        ? AppColors.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_upward_rounded,
                      color: _isComposing
                          ? Colors.white
                          : Theme.of(context).disabledColor,
                      size: 20,
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
