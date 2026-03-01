import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moto_comm_app_1/core/di/injection_container.dart';
import 'package:moto_comm_app_1/features/content/jots/presentation/bloc/jots_bloc.dart';
import 'package:moto_comm_app_1/features/content/jots/presentation/bloc/jots_event.dart';
import 'package:moto_comm_app_1/features/content/jots/presentation/bloc/jots_state.dart';
import 'package:moto_comm_app_1/features/content/jots/presentation/widgets/jot_card_widget.dart';
import 'package:moto_comm_app_1/features/interaction/presentation/widgets/comments_sheet.dart';

class JotFeedView extends StatefulWidget {
  const JotFeedView({super.key});

  @override
  State<JotFeedView> createState() => _JotFeedViewState();
}

class _JotFeedViewState extends State<JotFeedView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  late final JotsBloc _jotsBloc;

  @override
  void initState() {
    super.initState();
    _jotsBloc = sl<JotsBloc>()..add(const FetchJotsFeedEvent());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _jotsBloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (_isNearBottom) {
      _jotsBloc.add(const FetchMoreJotsFeedEvent());
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _onRefresh() async {
    _jotsBloc.add(const FetchJotsFeedEvent(isRefresh: true));
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _jotsBloc,
      child: BlocBuilder<JotsBloc, JotsState>(
        builder: (context, state) {
          if (state.status == JotsStatus.loading && state.jots.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == JotsStatus.failure && state.jots.isEmpty) {
            return _FeedError(onRetry: () => _jotsBloc.add(const FetchJotsFeedEvent(isRefresh: true)), message: state.errorMessage);
          }

          if (state.jots.isEmpty) {
            return const _FeedEmpty();
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              key: const PageStorageKey('jot_feed_list'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 80,
              ),
              itemCount: state.hasReachedMax
                  ? state.jots.length
                  : state.jots.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.jots.length) {
                  return state.isFetchingMore
                      ? const _BottomLoader()
                      : const SizedBox(height: 48);
                }

                final jot = state.jots[index];
                return JotCardWidget(
                  jot: jot,
                  onLike: () => _jotsBloc.add(LikeJotEvent(jotId: jot.id)),
                  onComment: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CommentsSheet(contentId: jot.id),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _BottomLoader extends StatelessWidget {
  const _BottomLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz hiç jot paylaşımı yok. İlk sen yaz!',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;

  const _FeedError({required this.onRetry, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message.isNotEmpty ? message : 'Akış yüklenemedi',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
