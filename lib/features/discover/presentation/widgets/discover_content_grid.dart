import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    if (_isBottom) {
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
    if (widget.content.isEmpty) {
      return const Center(child: Text("Henüz keşfedilecek bir içerik yok."));
    }

    return MasonryGridView.count(
      controller: _scrollController,
      crossAxisCount: 3,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      itemCount: widget.hasReachedMax ? widget.content.length : widget.content.length + 1,
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemBuilder: (context, index) {
        if (index >= widget.content.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final item = widget.content[index];
        return _GridItem(
          item: item,
          onTap: () => widget.onTap(widget.content, index),
        );
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
    final bool isReel = item.type == 2;
    final String? imageUrl = isReel ? item.thumbnailUrl : item.mediaUrl;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        // Reels için daha dikey (2:3), Normal postlar için kare (1:1)
        aspectRatio: isReel ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(2),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              else
                const Icon(Icons.image, color: Colors.grey),
              
              // Reel İkonu
              if (isReel)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
