import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../bloc/comments_bloc.dart';
import '../bloc/comments_event.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../bloc/comments_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/comment_entity.dart';

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
          expand: false, // Sheet'in içeriği kadar yer kaplaması için
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const _SheetHeader(),
                  Divider(height: 1, color: Theme.of(context).dividerColor),

                  // Liste Alanı
                  Expanded(
                    child: _CommentsList(scrollController: scrollController),
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
// 1. HEADER WIDGET (Tutma çubuğu ve Başlık)
// -----------------------------------------------------------------------------
class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // Gri Çubuk
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Yorumlar',
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
// 2. LIST WIDGET (Yorumların Listelendiği Alan)
// -----------------------------------------------------------------------------
class _CommentsList extends StatelessWidget {
  final ScrollController scrollController;

  const _CommentsList({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsBloc, CommentsState>(
      builder: (context, state) {
        if (state.status == CommentsStatus.loading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (state.status == CommentsStatus.failure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'Yorumlar yüklenirken hata oluştu',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

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
                  ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Henüz yorum yok.',
                  style: AppTextStyles.h3.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sessizliği bozan ilk kişi sen ol!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: state.comments.length,
          separatorBuilder: (c, i) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final comment = state.comments[index];
            return _CommentItem(comment: comment);
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 3. COMMENT ITEM (Tekil Yorum Görünümü)
// -----------------------------------------------------------------------------
class _CommentItem extends StatelessWidget {
  // Buradaki 'dynamic' yerine kendi Entity tipini yazmalısın (örn: CommentEntity)
  final dynamic comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey[200],
          backgroundImage:
              comment.userAvatar != null && comment.userAvatar!.isNotEmpty
              ? NetworkImage(comment.userAvatar!)
              : null,
          child: (comment.userAvatar == null || comment.userAvatar!.isEmpty)
              ? Text(
                  comment.username[0].toUpperCase(),
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
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 14,
                  height: 1.3,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              // Yanıtla butonu eklenebilir
              /*
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Yanıtla",
                  style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              */
            ],
          ),
        ),
        // More button (Delete option)
        _CommentMoreButton(comment: comment),
      ],
    );
  }

  // Basit tarih formatlayıcı
  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } else if (difference.inDays >= 1) {
      return "${difference.inDays}g";
    } else if (difference.inHours >= 1) {
      return "${difference.inHours}sa";
    } else if (difference.inMinutes >= 1) {
      return "${difference.inMinutes}dk";
    } else {
      return "Az önce";
    }
  }
}

class _CommentMoreButton extends StatelessWidget {
  final CommentEntity comment;

  const _CommentMoreButton({required this.comment});

  @override
  Widget build(BuildContext context) {
    // Listen to AuthProvider changes (e.g. when user is restored)
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    final currentUser = authProvider.currentUser;

    // --- BU KISMI EKLE ---
    // Giriş yapan kullanıcının ID'si
    final currentUserId = authProvider.currentUser?.id;

    // Yorumu atan kullanıcının ID'si
    final commentUserId = comment.userId;

    // --- KONSOLA YAZDIRIYORUZ ---
    print("######################################");
    print(
      "BENİM ID (Auth): '$currentUserId' (Tipi: ${currentUserId.runtimeType})",
    );
    print(
      "YORUM SAHİBİ ID: '$commentUserId' (Tipi: ${commentUserId.runtimeType})",
    );

    // Eşleşme kontrolü (Her ikisini de string yapıp karşılaştırıyoruz)
    final bool isOwner = currentUserId.toString() == commentUserId.toString();
    print("EŞLEŞİYOR MU? : $isOwner");
    print("######################################");
    // ------------------------------------------

    // Eğer eşleşme yoksa buton boş döner
    if (!isOwner) {
      // Test amaçlı buraya 'false' olsa bile görünmesi için geçici bir ikon koyabilirsin
      // return const Icon(Icons.lock, color: Colors.grey);
      return const SizedBox();
    }

    // Kullanıcı sahibiyse Sil butonunu göster
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'delete') {
          _showDeleteConfirmation(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Sil', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    // Capture the BLoC *before* showing the dialog, as the dialog's context is different.
    final commentsBloc = context.read<CommentsBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yorumu Sil'),
        content: const Text('Bu yorumu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () {
              commentsBloc.add(
                DeleteCommentEvent(commentId: comment.id, contentId: 0),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. INPUT AREA (Yorum Yazma Alanı)
// -----------------------------------------------------------------------------
class _CommentInputArea extends StatefulWidget {
  final int contentId;

  const _CommentInputArea({required this.contentId});

  @override
  State<_CommentInputArea> createState() => _CommentInputAreaState();
}

class _CommentInputAreaState extends State<_CommentInputArea> {
  final TextEditingController _controller = TextEditingController();
  bool _isComposing = false; // Butonun aktifliği için

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final isNotEmpty = _controller.text.trim().isNotEmpty;
      if (_isComposing != isNotEmpty) {
        setState(() {
          _isComposing = isNotEmpty;
        });
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
    FocusScope.of(context).unfocus(); // Klavye kapansın istersen
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16,
      ), // SafeArea için alttan boşluk
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                // AppInputField filled style matches the previous grey background
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
