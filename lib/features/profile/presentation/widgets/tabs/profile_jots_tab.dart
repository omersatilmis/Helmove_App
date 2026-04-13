import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/di/injection_container.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/features/content/jots/presentation/bloc/jots_bloc.dart';
import 'package:helmove/features/content/jots/presentation/bloc/jots_event.dart';
import 'package:helmove/features/content/jots/presentation/bloc/jots_state.dart';
import 'package:helmove/features/content/jots/presentation/widgets/jot_card_widget.dart';
import 'package:helmove/features/interaction/presentation/widgets/comments_sheet.dart';

class ProfileJotsTab extends StatefulWidget {
  final bool isOwnProfile;
  final int? viewedUserId;

  const ProfileJotsTab({
    super.key,
    required this.isOwnProfile,
    required this.viewedUserId,
  });

  @override
  State<ProfileJotsTab> createState() => _ProfileJotsTabState();
}

class _ProfileJotsTabState extends State<ProfileJotsTab>
    with AutomaticKeepAliveClientMixin {
  late JotsBloc _jotsBloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _jotsBloc = sl<JotsBloc>();
    _scrollController.addListener(_onScroll);

    // Auth ve Profile provider'dan verileri güvenli şekilde al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJotsForUser(widget.viewedUserId);
    });
  }

  @override
  void didUpdateWidget(covariant ProfileJotsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewedUserId != widget.viewedUserId) {
      _loadJotsForUser(widget.viewedUserId, isRefresh: true);
    }
  }

  void _loadJotsForUser(int? userId, {bool isRefresh = false}) {
    if (userId == null) return;
    _jotsBloc.add(FetchUserJotsEvent(userId: userId, isRefresh: isRefresh));
  }

  @override
  void dispose() {
    _jotsBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final currentState = _jotsBloc.state;
      // Duplicate fetch prevention
      if (currentState.isFetchingMore || currentState.hasReachedMax) return;
      final targetUserId = widget.viewedUserId;
      if (targetUserId != null) {
        _jotsBloc.add(FetchMoreUserJotsEvent(userId: targetUserId));
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  // Yeni Jot oluşturma sayfasını aç
  void _openCreateJot() async {
    if (!widget.isOwnProfile) return;

    final result = await context.push<String>('/create_jots');

    if (result != null && result.isNotEmpty) {
      // Dönen text ile create event'i tetikle
      _jotsBloc.add(CreateJotEvent(text: result));
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var theme = Theme.of(context);

    // BlocProvider ile sarmalıyoruz ki alt widgetlar (varsa) erişebilsin
    // Ama burada direkt kullanıyoruz.
    return BlocProvider.value(
      value: _jotsBloc,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: widget.isOwnProfile
            ? FloatingActionButton(
                onPressed: _openCreateJot,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.edit_note_rounded, size: 28),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        body: BlocConsumer<JotsBloc, JotsState>(
          listener: (context, state) {
            if (state.createStatus == JotsStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Jot gönderildi! 🚀")),
              );
            } else if (state.createStatus == JotsStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Hata: ${state.createError}"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == JotsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == JotsStatus.failure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Yüklenirken bir sorun oluştu",
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => _loadJotsForUser(widget.viewedUserId),
                      child: const Text("Tekrar Dene"),
                    ),
                  ],
                ),
              );
            }

            if (state.status == JotsStatus.success && state.jots.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha:0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Henüz hiç jot yok.",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadJotsForUser(widget.viewedUserId, isRefresh: true);
                // Bloc tamamlanana kadar beklemek şık olur ama şimdilik fire&forget
                // (Bloc state değişince UI güncellenir)
                await Future.delayed(const Duration(seconds: 1));
              },
              child: CustomScrollView(
                key: const PageStorageKey('jots_tab'),
                controller: _scrollController, // Pagination için önemli
                slivers: [
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Loading indicator en altta
                        if (index >= state.jots.length) {
                          return state.isFetchingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox(
                                  height: 50,
                                ); // Boşluk bırakalım ki scroll tetiklenebilsin
                        }

                        final jot = state.jots[index];
                        return JotCardWidget(
                          jot: jot,
                          currentUserId: state.currentUserId,
                          onLike: () {
                            context.read<JotsBloc>().add(
                              LikeJotEvent(jotId: jot.id),
                            );
                          },
                          onDelete: () {
                            context.read<JotsBloc>().add(
                              DeleteJotEvent(jotId: jot.id),
                            );
                          },
                          onComment: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  CommentsSheet(contentId: jot.id),
                            );
                          },
                        );
                      },
                      childCount: state.hasReachedMax
                          ? state.jots.length
                          : state.jots.length + 1,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
