import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Haptic Feedback (Titreşim) için eklendi
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import '../../../../../core/constants/report_enums.dart';
import '../../../../help/presentation/widgets/report_bottom_sheet.dart';
import '../../domain/entities/jot_entity.dart';
import '../pages/jot_detail_page.dart';

class JotCardWidget extends StatelessWidget {
  final JotEntity jot;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;
  final int? currentUserId;
  final bool isDetailView;

  const JotCardWidget({
    super.key,
    required this.jot,
    this.onLike,
    this.onComment,
    this.onDelete,
    this.currentUserId,
    this.isDetailView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurface.withValues(alpha: 0.6);

    final isOwner = currentUserId != null && jot.userId == currentUserId;

    final firstName = jot.firstName ?? jot.username ?? "Kullanıcı";
    final lastName = jot.lastName ?? "";
    final userName = jot.username ?? "user";
    final content = jot.text ?? "";
    final profileImage =
        jot.userProfilePictureUrl ?? 'assets/icons/ic_profile.png';
    final timeAgo = _formatDate(jot.createdAt);
    final bikeModel = jot.bikeModel;

    // KART YAPISI: Alttaki ince çizgiyi kaldırıp Threads/X tarzı 8px "havada duran" kart boşluğu verdik
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(
                alpha: 0.1,
              ), // Çok hafif saydamlık
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: isDetailView
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              JotDetailPage(jot: jot, currentUserId: currentUserId),
                        ),
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ), // Ferahlatılmış padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. HEADER ---
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Avatarı tepeye hizaladık
                      children: [
                        // AVATAR ÇERÇEVESİ: Tatlı bir premium halka eklendi
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: profileImage.startsWith('http')
                                ? CachedNetworkImageProvider(profileImage)
                                : AssetImage(profileImage) as ImageProvider,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      "$firstName $lastName",
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (bikeModel != null) ...[
                                    const SizedBox(width: 8),
                                    // MOTOR ROZETİ: İkonlu, tok ve rütbe gibi duran etiket
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons
                                                .two_wheeler_rounded, // Minik motor ikonu
                                            size: 12,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            bikeModel,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(
                                height: 0,
                              ), // İsim ile username dikeyde yaklaştırıldı
                              Row(
                                children: [
                                  Text(
                                    "@$userName",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textSecondary,
                                    ),
                                  ),
                                  Text(
                                    " • $timeAgo",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // KEBAB MENU
                        Transform.translate(
                          offset: const Offset(
                            8,
                            -8,
                          ), // Sağa ve yukarı kaydırarak köşe hizasını iyileştirdik
                          child: IconButton(
                            icon: Icon(
                              Icons.more_horiz,
                              size: 20,
                              color: textSecondary,
                            ),
                            onPressed: () async {
                              HapticFeedback.lightImpact(); // Menü açılırken hafif titreşim
                              final renderBox =
                                  context.findRenderObject() as RenderBox;
                              final offset = renderBox.localToGlobal(
                                Offset.zero,
                              );

                              final value = await showMenu<String>(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                  offset.dx + renderBox.size.width - 40,
                                  offset.dy + 40,
                                  offset.dx + renderBox.size.width,
                                  offset.dy + 100,
                                ),
                                color: theme.colorScheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                items: [
                                  if (isOwner)
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            "Sil",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (!isOwner)
                                    PopupMenuItem(
                                      value: 'report',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.report_problem_outlined,
                                            color: textPrimary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "Bildir",
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );

                              if (!context.mounted) return;
                              if (value == 'delete') {
                                onDelete?.call();
                              } else if (value == 'report') {
                                ReportBottomSheet.show(
                                  context,
                                  targetId: jot.id.toString(),
                                  targetType: ReportTargetType.content,
                                );
                              }
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),

                    // --- 2. CONTENT ---
                    if (content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: Text(
                          content,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: textPrimary.withValues(alpha: 0.95),
                          ),
                        ),
                      ),

                    // --- 2.5 MEDIA ---
                    if (jot.mediaUrl != null && jot.mediaUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 4),
                        // GÖRSEL ÇERÇEVESİ: İncecik saydam bir border ile resmi toklaştırdık
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              15,
                            ), // Border içine otursun diye 1px küçük
                            child: Container(
                              constraints: const BoxConstraints(
                                maxHeight: 350, // Biraz daha dengeli yükseklik
                              ),
                              width: double.infinity,
                              child: CachedNetworkImage(
                                imageUrl: jot.mediaUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        color: textSecondary,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Görsel yüklenemedi",
                                        style: TextStyle(color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // --- 3. ACTIONS ---
                    // YERLEŞİM: Etkileşimler sola, dağıtım sağa. Spacer() ile arayı açtık.
                    Row(
                      children: [
                        _ActionButton(
                          icon: Icons.mode_comment_outlined,
                          label: jot.commentCount.toString(),
                          onTap: () {
                            HapticFeedback.lightImpact(); // Titreşim
                            onComment?.call();
                          },
                        ),
                        const SizedBox(
                          width: 24,
                        ), // Butonlar arası ferah boşluk
                        _ActionButton(
                          icon: Icons.favorite_border_rounded,
                          activeIcon: Icons.favorite_rounded,
                          label: jot.likeCount.toString(),
                          activeColor: Colors.red,
                          isActive: jot.isLiked,
                          onTap: () {
                            HapticFeedback.lightImpact(); // Titreşim
                            onLike?.call();
                          },
                        ),
                        const Spacer(), // Geriye kalan boşluğu doldurur, share butonunu sağa iter
                        _ActionButton(
                          icon: Icons.share_rounded,
                          onTap: () {
                            HapticFeedback.lightImpact(); // Titreşim
                            final shareText = jot.text ?? "";
                            if (shareText.isNotEmpty) {
                              share_plus.SharePlus.instance.share(
                                share_plus.ShareParams(text: shareText),
                              );
                            }
                          },
                        ),
                        const SizedBox(
                          width: 4,
                        ), // Paylaş butonunu kebab menü ile aynı hizaya çekmek için sağdan küçük boşluk
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Şimdi";
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "Şimdi";
    if (diff.inMinutes < 60) return "${diff.inMinutes}dk";
    if (diff.inHours < 24) return "${diff.inHours}sa";
    return "${diff.inDays}g";
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String? label;
  final VoidCallback onTap;
  final Color? activeColor;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    this.activeIcon,
    this.label,
    required this.onTap,
    this.activeColor,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? (activeColor ?? theme.primaryColor)
        : theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final currentIcon = isActive ? (activeIcon ?? icon) : icon;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(isActive),
              tween: Tween<double>(begin: isActive ? 0.3 : 1.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: isActive ? Curves.elasticOut : Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(currentIcon, size: 20, color: color),
                );
              },
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500, // Sayıları biraz daha tok yaptık
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
