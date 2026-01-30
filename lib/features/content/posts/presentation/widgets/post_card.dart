import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🔥 ŞART
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../domain/entities/post_entity.dart';

class PostCardModern extends StatefulWidget {
  final PostEntity post;
  final VoidCallback? onDelete;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final bool isCurrentUser;

  const PostCardModern({
    super.key,
    required this.post,
    this.onDelete,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
    this.isCurrentUser = false,
  });

  @override
  State<PostCardModern> createState() => _PostCardModernState();
}

class _PostCardModernState extends State<PostCardModern>
    with SingleTickerProviderStateMixin {
  bool _hideUI = false; // UI Gizleme durumu
  late AnimationController _likeController; // Like animasyonu için
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    // Kalp animasyonu ayarları (Ufak bir büyüme/küçülme efekti)
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

  // Like butonuna basılınca çalışacak efekt
  void _animateLike() {
    _likeController.forward().then((_) => _likeController.reverse());
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Eğer resim yoksa postun yüksekliği daha az olsun
    final bool hasMedia =
        widget.post.mediaUrl != null && widget.post.mediaUrl!.isNotEmpty;

    return GestureDetector(
      // Ekrana basılı tutunca UI gizlenir, bırakınca gelir
      onLongPressStart: (_) => setState(() => _hideUI = true),
      onLongPressEnd: (_) => setState(() => _hideUI = false),
      onTap: () {
        // Tek tıklamada gizlilik açıksa kapat, yoksa detay açılabilir (ileride)
        if (_hideUI) setState(() => _hideUI = false);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 24), // Kenar boşlukları
        // Kareye yakın bir oran (4:5 instagram oranı veya 1:1)
        height: hasMedia ? 450 : 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24), // Modern yuvarlak köşeler
          color: AppColors.darkSurface, // Resim yoksa zemin rengi
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
              // --------------------------
              // KATMAN 1: ARKA PLAN (MEDYA)
              // --------------------------
              Positioned.fill(
                child: hasMedia
                    ? CachedNetworkImage(
                        imageUrl: widget.post.mediaUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.darkSurfaceContainer,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.darkSurface,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        // Resim yoksa gradient arka plan
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

              // --------------------------
              // KATMAN 2: KARARTMA (GRADIENT)
              // --------------------------
              if (!_hideUI)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 300, // Alt kısmı karart
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),

              // --------------------------
              // KATMAN 3: SAĞ BUTONLAR
              // --------------------------
              if (!_hideUI)
                Positioned(
                  right: 12,
                  bottom: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Like Butonu
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

                      // Yorum Butonu
                      _SideActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: _formatCount(widget.post.commentCount),
                        onTap: widget.onComment,
                      ),
                      const SizedBox(height: 20),

                      // Paylaş Butonu
                      _SideActionButton(
                        icon: Icons.send_rounded, // Telegram/DM tarzı ikon
                        label: "Paylaş",
                        iconSize: 26,
                        onTap: widget.onShare,
                      ),
                      const SizedBox(height: 20),

                      // Kaydet Butonu
                      _SideActionButton(
                        icon: Icons.bookmark_border_rounded,
                        label: "Kaydet",
                        onTap: widget.onSave,
                      ),
                    ],
                  ),
                ),

              // --------------------------
              // KATMAN 4: ALT BİLGİ (PROFIL & TEXT)
              // --------------------------
              if (!_hideUI)
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 80, // Sağ butonlara çarpmaması için boşluk
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Profil Satırı
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundImage:
                                  widget.post.userProfileImage != null
                                  ? CachedNetworkImageProvider(
                                      widget.post.userProfileImage!,
                                    )
                                  : null,
                              backgroundColor: AppColors.primary,
                              child: widget.post.userProfileImage == null
                                  ? Text(
                                      widget.post.username.isNotEmpty
                                          ? widget.post.username[0]
                                                .toUpperCase()
                                          : "?",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
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
                                  widget.post.username,
                                  style: AppTextStyles.h3.copyWith(
                                    color: Colors.white,
                                    fontSize: 15,
                                    shadows: [
                                      const Shadow(
                                        blurRadius: 4,
                                        color: Colors.black,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                // Tarih bilgisi eklenebilir
                                // Text("2s önce", style: TextStyle(color: Colors.white70, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Post Yazısı
                      if (widget.post.text.isNotEmpty)
                        Text(
                          widget.post.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 14,
                            height: 1.3,
                            shadows: [
                              const Shadow(
                                blurRadius: 2,
                                color: Colors.black,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

              // --------------------------
              // KATMAN 5: SİLME MENÜSÜ (Opsiyonel)
              // --------------------------
              if (!_hideUI)
                Positioned(
                  top: 16,
                  right: 16,
                  child: PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_horiz,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    color: AppColors.darkSurface,
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'share') {
                        widget.onShare?.call();
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.darkSurface,
                            title: const Text(
                              'Postu Sil',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              'Bu gönderiyi silmek istediğine emin misin?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('İptal'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close dialog
                                  widget.onDelete?.call();
                                },
                                child: const Text(
                                  'Sil',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(
                              Icons.send_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Paylaş',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isCurrentUser)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Sil',
                                style: TextStyle(color: AppColors.error),
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
    );
  }

  // Sayıları kısaltmak için yardımcı metod (1200 -> 1.2K)
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

// Yardımcı Yan Buton Widget'ı
class _SideActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double iconSize;

  const _SideActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = Colors.white,
    this.iconSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // İkonun arkasına hafif bir gölge atıyoruz ki karışık resimlerde de görünsün
          Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  blurRadius: 3,
                  color: Colors.black,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
