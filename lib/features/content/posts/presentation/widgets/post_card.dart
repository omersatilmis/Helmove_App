import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/utils/image_url_extensions.dart';
import '../../../../../core/constants/report_enums.dart';
import '../../../../help/presentation/widgets/report_bottom_sheet.dart';
import '../../../../../core/config/app_feature_flags.dart';
import '../../domain/entities/post_entity.dart';

class PostCardModern extends StatefulWidget {
  final PostEntity post;
  final int? currentUserId;
  final VoidCallback? onDelete;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onReport;

  const PostCardModern({
    super.key,
    required this.post,
    this.currentUserId,
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
    final bool isOwner =
        widget.currentUserId != null &&
        widget.currentUserId! > 0 &&
        widget.currentUserId == widget.post.userId;
    final displayName = widget.post.displayName.trim().isEmpty
        ? widget.post.username
        : widget.post.displayName;

    final bool hasMedia =
        widget.post.mediaUrl != null && widget.post.mediaUrl!.isNotEmpty;
    final mediaUrl = widget.post.mediaUrl.toFeedThumbnail();
    final avatarUrl = widget.post.userProfileImage.toAvatarThumbnail();

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
              color: Colors.black.withValues(alpha: 0.3),
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
                        imageUrl: mediaUrl,
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

              // KATMAN 2: SİYAH KARARTMA (ÜST GRADIENT - PROFİL BİLGİSİ İÇİN)
              if (!_hideUI)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120, // Üst kısmı hafifçe karartmak için
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 1.0],
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // KATMAN 2: SİYAH KARARTMA (ALT GRADIENT - İÇERİK İÇİN)
              if (!_hideUI)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 180, // Okunurluk için yükseklik 180px'e düşürüldü
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                            Colors.black.withValues(alpha: 1.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // KATMAN 2.5: ÜST BİLGİ (PROFİL) - YENİ KONUM
              if (!_hideUI)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 60,
                  child: GestureDetector(
                    onTap: () => context.push('/profile/${widget.post.userId}'),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage: avatarUrl.isNotEmpty
                                ? CachedNetworkImageProvider(avatarUrl)
                                : null,
                            child: avatarUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: AppTextStyles.h3.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    const Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.post.username != displayName)
                                Text(
                                  "@${widget.post.username}",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    shadows: [
                                      const Shadow(
                                        color: Colors.black54,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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
                          if (value == 'report') {
                            ReportBottomSheet.show(
                              context,
                              targetId: widget.post.id.toString(),
                              targetType: ReportTargetType.content,
                            );
                            widget.onReport?.call();
                          }
                        },
                        itemBuilder: (context) => [
                          if (AppFeatureFlags.showPostSend)
                            _buildPopupItem(
                              'share',
                              Icons.share_outlined,
                              AppLocalizations.of(context)!.share,
                            ),
                          _buildPopupItem(
                            'report',
                            Icons.report_gmailerrorred_rounded,
                            AppLocalizations.of(context)!.report,
                          ),
                          if (isOwner)
                            _buildPopupItem(
                              'delete',
                              Icons.delete_outline,
                              AppLocalizations.of(context)!.delete,
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
                          if (AppFeatureFlags.showPostSend) ...[
                            _SideActionButton(
                              icon: Icons.send_rounded,
                              label: AppLocalizations.of(context)!.send,
                              onTap: widget.onShare,
                            ),
                            const SizedBox(height: 20),
                          ],
                          // Kaydet
                          if (AppFeatureFlags.showPostKaydetButton)
                            _SideActionButton(
                              icon: Icons.bookmark_border_rounded,
                              label: AppLocalizations.of(context)!.save,
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
                      if (widget.post.text.isNotEmpty)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final textStyle = const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            );

                            final span = TextSpan(
                              text: widget.post.text,
                              style: textStyle,
                            );

                            final tp = TextPainter(
                              text: span,
                              maxLines: 2,
                              textDirection: TextDirection.ltr,
                            );
                            tp.layout(maxWidth: constraints.maxWidth);

                            if (tp.didExceedMaxLines) {
                              return RichText(
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: widget.post.text,
                                      style: textStyle,
                                    ),
                                    TextSpan(
                                      text: AppLocalizations.of(context)!.continueTextShort,
                                      style: textStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Text(
                              widget.post.text,
                              style: textStyle,
                            );
                          },
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
        title: Text(
          AppLocalizations.of(context)!.deleteConfirmTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteConfirmContent,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.white54)),
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
            child: Text(
              AppLocalizations.of(context)!.delete,
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
