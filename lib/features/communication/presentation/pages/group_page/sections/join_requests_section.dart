import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:helmove/core/di/injection_container.dart' as di;
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/core/utils/image_url_extensions.dart';
import 'package:helmove/features/attendance_management/domain/entities/participant_entity.dart';
import 'package:helmove/features/group_ride/presentation/bloc/ride_detail/ride_detail_bloc.dart';
import 'package:helmove/features/group_ride/presentation/bloc/ride_detail/ride_detail_event.dart';
import 'package:helmove/features/group_ride/presentation/bloc/ride_detail/ride_detail_state.dart';

/// [Grup Sürüşü] Bekleyen katılım isteklerini gösteren küçük sayı rozeti.
///
/// Katılımcı başlığındaki frosted butonların yanında yer kaplamadan durur;
/// üzerinde bekleyen istek sayısı yazar. Tıklanınca modal bottom sheet açılır ve
/// istekler oradan onaylanır/reddedilir. İstek yokken de tıklanabilir ("Henüz
/// katılım isteği yok").
///
/// Kendi içinde scoped bir [RideDetailBloc] kurar (katılımcı listesi + onay/ret)
/// → group-page'in mevcut bloc'larına dokunmaz. Sadece organizatöre gösterilir
/// (çağıran taraf kontrol eder; bloc da [RideDetailState.isOrganizer] türetir).
class JoinRequestsBadge extends StatelessWidget {
  final int rideId;
  final double size;

  const JoinRequestsBadge({super.key, required this.rideId, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RideDetailBloc>(
      create: (_) =>
          di.sl<RideDetailBloc>()..add(RideDetailRequested(rideId)),
      child: _BadgeButton(size: size),
    );
  }
}

class _BadgeButton extends StatelessWidget {
  final double size;
  const _BadgeButton({required this.size});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<RideDetailBloc, RideDetailState>(
      listenWhen: (p, c) =>
          c.feedbackMessage != null && p.feedbackSeq != c.feedbackSeq,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.feedbackMessage!),
              backgroundColor:
                  state.feedbackIsError ? colorScheme.error : Colors.green,
            ),
          );
      },
      builder: (context, state) {
        final count = state.pendingParticipants.length;
        return _FrostedCountButton(
          count: count,
          size: size,
          highlight: count > 0,
          onTap: () => _openSheet(context, context.read<RideDetailBloc>()),
        );
      },
    );
  }

  void _openSheet(BuildContext context, RideDetailBloc bloc) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Scoped bloc sheet'in (overlay) context'inde bulunmaz → value ile taşı.
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const _JoinRequestsSheet(),
      ),
    );
  }
}

/// İçinde sayı yazan, diğer başlık butonlarıyla aynı buzlu cam stilinde yuvarlak
/// buton. [highlight] (bekleyen istek var) primary vurgusu verir.
class _FrostedCountButton extends StatelessWidget {
  final int count;
  final double size;
  final bool highlight;
  final VoidCallback onTap;

  const _FrostedCountButton({
    required this.count,
    required this.size,
    required this.highlight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final baseColor = isDark
        ? const Color(0xFF1E1E1E).withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.3);
    final borderColor = highlight
        ? colorScheme.primary.withValues(alpha: 0.7)
        : (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.5));
    final textColor = highlight
        ? colorScheme.primary
        : (isDark ? Colors.white : const Color(0xFF1F1F1F));

    return Tooltip(
      message: 'Katılım istekleri',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: highlight
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : baseColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderColor,
                  width: highlight ? 1.8 : 1.5,
                ),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Center(
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal içeriği: bekleyen istek listesi + onay/ret (veya boş durum).
class _JoinRequestsSheet extends StatelessWidget {
  const _JoinRequestsSheet();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<RideDetailBloc, RideDetailState>(
      builder: (context, state) {
        final pending = state.pendingParticipants;
        final loading =
            state.status == RideDetailStatus.loading && state.ride == null;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.how_to_reg_outlined,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Katılım istekleri (${pending.length})',
                        style: AppTextStyles.h3.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (pending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Henüz katılım isteği yok.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: pending.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 16,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                      itemBuilder: (_, i) => _RequestTile(
                        participant: pending[i],
                        busy: state.actionInProgress,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  final ParticipantEntity participant;
  final bool busy;

  const _RequestTile({required this.participant, required this.busy});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = _participantName(participant);
    final avatar = participant.profileImageUrl;
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    final message = participant.joinMessage?.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
          backgroundImage: hasAvatar
              ? CachedNetworkImageProvider(avatar.toAbsoluteImageUrl())
              : null,
          child: hasAvatar
              ? null
              : Text(
                  _initials(name),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (message != null && message.isNotEmpty)
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Onayla',
          onPressed: busy
              ? null
              : () => context
                  .read<RideDetailBloc>()
                  .add(ParticipantApproved(participant.userId)),
          icon: const Icon(Icons.check_circle_outline_rounded),
          color: Colors.green,
        ),
        IconButton(
          tooltip: 'Reddet',
          onPressed: busy
              ? null
              : () => context
                  .read<RideDetailBloc>()
                  .add(ParticipantRejected(participant.userId)),
          icon: const Icon(Icons.cancel_outlined),
          color: colorScheme.error,
        ),
      ],
    );
  }
}

String _participantName(ParticipantEntity p) {
  final full = '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim();
  if (full.isNotEmpty) return full;
  return p.username;
}

String _initials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}
