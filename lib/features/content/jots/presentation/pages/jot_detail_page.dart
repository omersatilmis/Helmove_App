import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/widgets/app_background.dart';
// Fixed relative path
import '../../../../interaction/presentation/bloc/comments_bloc.dart';
import '../../../../interaction/presentation/bloc/comments_event.dart';
import '../../../../interaction/presentation/bloc/comments_state.dart';
import '../../../../../core/widgets/app_input_field.dart';
import '../../domain/entities/jot_entity.dart';
import '../widgets/jot_card_widget.dart';

class JotDetailPage extends StatefulWidget {
  final JotEntity jot;
  final int? currentUserId;

  const JotDetailPage({
    super.key,
    required this.jot,
    this.currentUserId,
  });

  @override
  State<JotDetailPage> createState() => _JotDetailPageState();
}

class _JotDetailPageState extends State<JotDetailPage> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => sl<CommentsBloc>()
        ..add(LoadCommentsEvent(
          contentId: widget.jot.id,
          page: 1,
          limit: 20,
        )),
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Jot'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: JotCardWidget(
                        jot: widget.jot,
                        currentUserId: widget.currentUserId,
                        onComment: () => _commentFocusNode.requestFocus(),
                        isDetailView: true,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Yanıtlar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    BlocBuilder<CommentsBloc, CommentsState>(
                      builder: (context, state) {
                        if (state.status == CommentsStatus.loading && state.comments.isEmpty) {
                          return const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        
                        if (state.comments.isEmpty) {
                          return const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text('Henüz yorum yok.'),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final comment = state.comments[index];
                              return ListTile(
                                leading: GestureDetector(
                                  onTap: () => context.push('/profile/${comment.userId}'),
                                  child: CircleAvatar(
                                    backgroundImage: comment.userAvatar != null
                                        ? CachedNetworkImageProvider(comment.userAvatar!)
                                        : null,
                                    child: comment.userAvatar == null 
                                        ? Text(comment.username[0].toUpperCase())
                                        : null,
                                  ),
                                ),
                                title: GestureDetector(
                                  onTap: () => context.push('/profile/${comment.userId}'),
                                  child: Row(
                                    children: [
                                      Text(
                                        comment.username,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatTimeAgo(comment.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                subtitle: Text(comment.text),
                              );
                            },
                            childCount: state.comments.length,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _CommentInput(
                contentId: widget.jot.id,
                controller: _commentController,
                focusNode: _commentFocusNode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 1) return "${difference.inDays}g";
    if (difference.inHours >= 1) return "${difference.inHours}sa";
    if (difference.inMinutes >= 1) return "${difference.inMinutes}dk";
    return "Şimdi";
  }
}

class _CommentInput extends StatelessWidget {
  final int contentId;
  final TextEditingController controller;
  final FocusNode focusNode;

  const _CommentInput({
    required this.contentId,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
        ),
        padding: EdgeInsets.only(
          bottom: safeBottom + 8,
          left: 16,
          right: 8,
          top: 8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AppInputField(
                controller: controller,
                focusNode: focusNode,
                type: AppInputType.standard,
                variant: AppInputVariant.filled,
                size: AppInputSize.small,
                hint: 'Yanıtını paylaş...',
                minLines: 1,
                maxLines: 4,
                radius: 22,
                showFocusBorder: false,
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final hasText = value.text.trim().isNotEmpty;
                return BlocBuilder<CommentsBloc, CommentsState>(
                  builder: (context, state) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0, left: 8.0),
                      child: TextButton(
                        onPressed: (state.isPostingComment || !hasText)
                            ? null
                            : () {
                                final text = controller.text.trim();
                                if (text.isNotEmpty) {
                                  context.read<CommentsBloc>().add(
                                        AddCommentEvent(contentId: contentId, text: text),
                                      );
                                  controller.clear();
                                  focusNode.unfocus();
                                }
                              },
                        style: TextButton.styleFrom(
                          backgroundColor: hasText ? colorScheme.primary : Colors.transparent,
                          foregroundColor: hasText ? colorScheme.onPrimary : colorScheme.onSurface.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        child: state.isPostingComment
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                                ),
                              )
                            : Text(
                                'Yanıtla',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: hasText ? colorScheme.onPrimary : colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
