import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/post_entity.dart';

class PostCardModern extends StatefulWidget {
  final PostEntity post;
  final VoidCallback? onDelete;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onReport;

  const PostCardModern({
    super.key,
    required this.post,
    this.onDelete,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onReport,
  });

  @override
  State<PostCardModern> createState() => _PostCardModernState();
}

class _PostCardModernState extends State<PostCardModern>
    with SingleTickerProviderStateMixin {
  bool _hideUI = false;
  late AnimationController _likeController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _animateLike() {
    _likeController.forward().then((_) => _likeController.reverse());
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    // 1. ADIM: AuthProvider'dan mevcut kullanıcıyı al
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    // 2. ADIM: Kesin sahiplik kontrolü (Zırhlı Mantık)
    final bool isOwner =
        currentUser != null &&
        currentUser.id != 0 &&
        currentUser.id.toString() == widget.post.userId.toString();

    debugPrint('--- Post Ownership Debug ---');
    debugPrint('Post ID: ${widget.post.id}');
    debugPrint('Current User ID: ${currentUser?.id}');
    debugPrint('Post User ID: ${widget.post.userId}');
    debugPrint('Is Owner: $isOwner');
    debugPrint('---------------------------');

    final bool hasMedia =
        widget.post.mediaUrl != null && widget.post.mediaUrl!.isNotEmpty;

    return GestureDetector(
      // Basılı tutunca UI gizleme
      onLongPressStart: (_) => setState(() => _hideUI = true),
      onLongPressEnd: (_) => setState(() => _hideUI = false),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 24),
        height: hasMedia ? 450 : 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.darkSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // KATMAN 1: ARKA PLAN (MEDYA)
              Positioned.fill(
                child: hasMedia
                    ? CachedNetworkImage(
                        imageUrl: widget.post.mediaUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.darkSurfaceContainer,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.darkSurface,
                              AppColors.darkSurfaceContainer,
                            ],
                          ),
                        ),
                      ),
              ),

              // KATMAN 2: SİYAH KARARTMA (GRADIENT)
              if (!_hideUI)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 300, // Okunurluk için 300px derinlik
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(1.0),
                        ],
                      ),
                    ),
                  ),
                ),

              // KATMAN 3: SAĞ AKSİYON PANELİ (Dikey Hizalama)
              if (!_hideUI)
                Positioned(
                  right: 12,
                  top: 12,
                  bottom: 20,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Seçenekler (Üst)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 28,
                        ),
                        color: const Color(0xFF252525),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        offset: const Offset(0, 45),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteConfirmDialog(context);
                          }
                          if (value == 'share') widget.onShare?.call();
                          if (value == 'report') widget.onReport?.call();
                        },
                        itemBuilder: (context) => [
                          _buildPopupItem(
                            'share',
                            Icons.share_outlined,
                            'Paylaş',
                          ),
                          _buildPopupItem(
                            'report',
                            Icons.report_gmailerrorred_rounded,
                            'Şikayet Et',
                          ),
                          if (isOwner)
                            _buildPopupItem(
                              'delete',
                              Icons.delete_outline,
                              'Sil',
                              color: Colors.redAccent,
                            ),
                        ],
                      ),

                      // Aksiyon Butonları (Alt)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Like
                          ScaleTransition(
                            scale: _likeAnimation,
                            child: _SideActionButton(
                              icon: widget.post.isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              label: _formatCount(widget.post.likeCount),
                              color: widget.post.isLiked
                                  ? const Color(0xFFFF3040)
                                  : Colors.white,
                              onTap: _animateLike,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Yorum
                          _SideActionButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: _formatCount(widget.post.commentCount),
                            onTap: widget.onComment,
                          ),
                          const SizedBox(height: 20),
                          // Gönder
                          _SideActionButton(
                            icon: Icons.send_rounded,
                            label: "Gönder",
                            onTap: widget.onShare,
                          ),
                          const SizedBox(height: 20),
                          // Kaydet
                          _SideActionButton(
                            icon: Icons.bookmark_border_rounded,
                            label: "Kaydet",
                            onTap: widget.onSave,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // KATMAN 4: ALT BİLGİ (PROFİL & TEXT)
              if (!_hideUI)
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage:
                                widget.post.userProfileImage != null
                                ? CachedNetworkImageProvider(
                                    widget.post.userProfileImage!,
                                  )
                                : null,
                            child: widget.post.userProfileImage == null
                                ? const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.post.username,
                              style: AppTextStyles.h3.copyWith(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (widget.post.text.isNotEmpty)
                        Text(
                          widget.post.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Samsung Style Delete Dialog
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Silinsin mi?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Bu gönderi kalıcı olarak silinecek.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            child: const Text(
              'Sil',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String text, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(color: color ?? Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// Yan Buton Bileşeni
class _SideActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _SideActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
