import 'package:flutter/material.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../bloc/discover_bloc.dart';
import '../bloc/discover_event.dart';
import '../bloc/discover_state.dart';

class DiscoverSearchPage extends StatefulWidget {
  const DiscoverSearchPage({super.key});

  @override
  State<DiscoverSearchPage> createState() => _DiscoverSearchPageState();
}

class _DiscoverSearchPageState extends State<DiscoverSearchPage> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
    
    _searchController.addListener(() {
      if (_searchController.text.isNotEmpty != _showClearButton) {
        setState(() {
          _showClearButton = _searchController.text.isNotEmpty;
        });
      }
    });

    // Auto-focus the search bar when the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty) {
      context.read<DiscoverBloc>().add(SearchUsersEvent(query: trimmedQuery));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ARAMA SATIRI: Geri Butonu + Giriş Alanı (İstenen Modern Görünüm)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40),
                  ),
                  Expanded(
                    child: AppInputField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      type: AppInputType.discover,
                      hint: AppLocalizations.of(context)!.searchUserHint,
                      leadingIcon: Icons.search_rounded,
                      suffixWidget: _showClearButton 
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: _performSearch,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: BlocBuilder<DiscoverBloc, DiscoverState>(
        builder: (context, state) {
          if (state is DiscoverLoading) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          } 
          
          if (state is DiscoverFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.error_outline_rounded, size: 64, color: cs.error.withValues(alpha: 0.5)),
                   const SizedBox(height: 16),
                   Text(state.message),
                ],
              ),
            );
          } 
          
          if (state is DiscoverLoaded) {
            final results = state.results;
            if (results.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.userNotFound,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: results.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              separatorBuilder: (context, index) => Divider(
                height: 1, 
                indent: 80,
                color: theme.dividerColor.withValues(alpha: 0.05),
              ),
              itemBuilder: (context, index) {
                final user = results[index];
                return _UserSearchTile(user: user);
              },
            );
          }
          
          // Initial State
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_search_rounded, size: 64, color: cs.primary.withValues(alpha: 0.4)),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.searchFriends,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.searchByUsernameOrName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  ],
),
      ),
    );
  }
}

class _UserSearchTile extends StatelessWidget {
  final dynamic user; // FriendUserEntity or similar

  const _UserSearchTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 26,
          backgroundColor: cs.surfaceContainerLow,
          backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
              ? CachedNetworkImageProvider(user.profilePictureUrl!)
              : null,
          child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty
              ? Icon(Icons.person_rounded, color: cs.onSurfaceVariant)
              : null,
        ),
      ),
      title: Text(
        "${user.firstName ?? ''} ${user.lastName ?? ''}".trim().isNotEmpty 
            ? "${user.firstName} ${user.lastName}" 
            : user.username,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        "@${user.username}",
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.5),
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: cs.onSurface.withValues(alpha: 0.2),
      ),
      onTap: () {
        context.push('/profile/${user.id}');
      },
    );
  }
}
