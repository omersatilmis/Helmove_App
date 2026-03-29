import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:helmove/l10n/app_localizations.dart';
import '../../../content/posts/domain/entities/post_entity.dart';

class DiscoverContentGrid extends StatefulWidget {
  final List<PostEntity> content;
  final bool hasReachedMax;
  final void Function(List<PostEntity> content, int index) onTap;
  final VoidCallback onLoadMore;

  const DiscoverContentGrid({
    super.key,
    required this.content,
    required this.hasReachedMax,
    required this.onTap,
    required this.onLoadMore,
  });

  @override
  State<DiscoverContentGrid> createState() => _DiscoverContentGridState();
}

class _DiscoverContentGridState extends State<DiscoverContentGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !widget.hasReachedMax) {
      widget.onLoadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.content.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noDiscoveryContent,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return MasonryGridView.count(
      controller: _scrollController,
      crossAxisCount: 3,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      itemCount: widget.hasReachedMax
          ? widget.content.length
          : widget.content.length + 1,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        if (index >= widget.content.length) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }
        final item = widget.content[index];
        return _GridItem(item: item, onTap: () => widget.onTap(widget.content, index));
      },
    );
  }
}

class _GridItem extends StatelessWidget {
  final PostEntity item;
  final VoidCallback onTap;

  const _GridItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isReel = item.type == 2;
    // Öncelik: Thumbnail -> MediaUrl
    final String? imageUrl = (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty)
        ? item.thumbnailUrl
        : item.mediaUrl;

    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final hasText = item.text.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: isReel ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(4), // Hafif kavis
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. GÖRSEL VARSA GÖSTER
              if (hasImage)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surfaceContainerLow,
                  ),
                  errorWidget: (context, url, error) => _buildTextPlaceholder(theme),
                )
              // 2. GÖRSEL YOK AMA METİN VARSA (JOTLAR İÇİN)
              else if (hasText)
                _buildTextPlaceholder(theme)
              // 3. HİÇBİR ŞEY YOKSA İKON GÖSTER
              else
                Icon(
                  Icons.image_outlined,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 24,
                ),

              // Reel İkonu / Video Göstergesi
              if (isReel)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                
              // Tip Göstergesi (Opsiyonel: Jot için minik ikon)
              if (item.type == 0 && !hasImage)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Icon(
                    Icons.notes_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextPlaceholder(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.8),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        item.text,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
