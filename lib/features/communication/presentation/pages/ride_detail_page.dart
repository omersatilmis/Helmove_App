import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/core/utils/image_url_extensions.dart';
import 'package:helmove/core/widgets/app_background.dart';
import 'package:helmove/features/attendance_management/domain/entities/participant_entity.dart';
import 'package:helmove/features/group_ride/domain/entities/group_ride_summary.dart';
import 'package:helmove/features/group_ride/presentation/bloc/ride_detail/ride_detail_bloc.dart';
import 'package:helmove/features/group_ride/presentation/bloc/ride_detail/ride_detail_event.dart';
import 'package:helmove/features/group_ride/presentation/bloc/ride_detail/ride_detail_state.dart';
import 'package:helmove/features/group_ride/presentation/models/group_ride_args.dart';

/// [Tur Detayı] Grup dışındaki kullanıcıların gördüğü tur detay ekranı.
///
/// Detayı + kullanıcının katılım durumunu + katılımcıları yükler; alt aksiyon
/// barı kullanıcının ilişkisine göre uyarlanır (KATIL / Beklemede / Katıldın /
/// Organizatör). Header [summary] varken anında çizilir, detay arkadan gelir.
class GroupRideDetailPage extends StatelessWidget {
  final int rideId;
  final GroupRideSummary? summary;

  const GroupRideDetailPage({super.key, required this.rideId, this.summary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocConsumer<RideDetailBloc, RideDetailState>(
          listenWhen: (p, c) =>
              c.feedbackMessage != null && p.feedbackSeq != c.feedbackSeq,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.feedbackMessage!),
                  backgroundColor: state.feedbackIsError
                      ? colorScheme.error
                      : colorScheme.primary,
                ),
              );
          },
          builder: (context, state) {
            // Tam ekran hata (detay hiç yüklenemedi).
            if (state.status == RideDetailStatus.failure && state.ride == null) {
              return _ErrorView(
                message: state.error ?? 'Tur detayı yüklenemedi.',
                onRetry: () => context.read<RideDetailBloc>().add(
                  RideDetailRequested(rideId),
                ),
              );
            }

            final ride = state.ride;
            final loading =
                state.status == RideDetailStatus.loading && ride == null;

            return RefreshIndicator(
              onRefresh: () async => context.read<RideDetailBloc>().add(
                const RideDetailRefreshed(),
              ),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _CoverAppBar(
                    // Öncelik: detay rota görüntüsü → detay cover → özet rota
                    // görüntüsü → özet cover. (Header summary varken anında çizilir.)
                    imageUrl: ride?.routeImageUrl ??
                        ride?.coverImageUrl ??
                        summary?.routeImageUrl ??
                        summary?.coverImageUrl,
                  ),
                  if (loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    SliverToBoxAdapter(
                      child: _Body(state: state, summary: summary),
                    ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: BlocBuilder<RideDetailBloc, RideDetailState>(
          builder: (context, state) {
            if (state.ride == null) return const SizedBox.shrink();
            return _ActionBar(state: state);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kapak app bar
// ─────────────────────────────────────────────────────────────────────────────

class _CoverAppBar extends StatelessWidget {
  final String? imageUrl;
  const _CoverAppBar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = imageUrl;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 200,
      backgroundColor: colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: (url == null || url.isEmpty)
            ? Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.motorcycle_rounded,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              )
            : CachedNetworkImage(
                // Kapak tam genişlik + 200px: kart için üretilen küçük Mapbox
                // görüntüsü burada bulanık/zoomlu görünmesin diye boyut segmenti
                // detay kapağına uygun (yaklaşık 2:1) yüksek çözünürlüğe çıkarılır.
                imageUrl: url
                    .toMapboxStaticSize(width: 800, height: 420)
                    .toAbsoluteImageUrl(),
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(color: colorScheme.surfaceContainerHighest),
                errorWidget: (_, _, _) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.motorcycle_rounded,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gövde
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final RideDetailState state;
  final GroupRideSummary? summary;
  const _Body({required this.state, this.summary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ride = state.ride!;
    final occupancy =
        '${state.approvedOrCount(summary)}/${ride.maxParticipants}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ride.title,
                  style: AppTextStyles.h2.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _DifficultyBadge(difficulty: ride.difficulty),
            ],
          ),
          const SizedBox(height: 12),
          _OrganizerRow(state: state, summary: summary),
          const SizedBox(height: 16),
          _InfoTile(
            icon: Icons.place_outlined,
            label: 'Başlangıç',
            value: ride.startLocation,
          ),
          if (ride.endLocation.isNotEmpty)
            _InfoTile(
              icon: Icons.flag_outlined,
              label: 'Varış',
              value: ride.endLocation,
            ),
          _InfoTile(
            icon: Icons.event_outlined,
            label: 'Tarih',
            value: _formatFullDate(ride.startDateTime),
          ),
          _InfoTile(
            icon: Icons.motorcycle_outlined,
            label: 'Tarz',
            value: _styleLabel(ride.ridingStyle),
          ),
          _InfoTile(
            icon: Icons.group_outlined,
            label: 'Katılımcı',
            value: occupancy,
          ),
          if (ride.estimatedDistanceKm != null)
            _InfoTile(
              icon: Icons.straighten_outlined,
              label: 'Tahmini mesafe',
              value: '${ride.estimatedDistanceKm!.toStringAsFixed(0)} km',
            ),
          if (ride.estimatedDurationMinutes != null)
            _InfoTile(
              icon: Icons.schedule_outlined,
              label: 'Tahmini süre',
              value: _durationLabel(ride.estimatedDurationMinutes!),
            ),
          if ((ride.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(title: 'Açıklama', child: Text(ride.description!.trim())),
          ],
          if ((ride.requirements ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(
              title: 'Gereksinimler',
              child: Text(ride.requirements!.trim()),
            ),
          ],
          if (state.approvedParticipants.isNotEmpty) ...[
            const SizedBox(height: 20),
            _ParticipantsSection(participants: state.approvedParticipants),
          ],
          if (state.isOrganizer && state.pendingParticipants.isNotEmpty) ...[
            const SizedBox(height: 20),
            _PendingRequestsSection(
              participants: state.pendingParticipants,
              actionInProgress: state.actionInProgress,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

extension on RideDetailState {
  /// Katılımcı listesi geldiyse onaylananları say; gelmediyse summary'deki
  /// hazır sayacı kullan (non-member liste çekemeyince bile doğru görünsün).
  int approvedOrCount(GroupRideSummary? summary) {
    if (participants.isNotEmpty) return approvedParticipants.length;
    return summary?.currentParticipantCount ?? approvedParticipants.length;
  }
}

class _OrganizerRow extends StatelessWidget {
  final RideDetailState state;
  final GroupRideSummary? summary;
  const _OrganizerRow({required this.state, this.summary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Önce detay entity'si (backend GET /{id} organizatörü döndürür); o yoksa
    // keşfetten gelen summary. Böylece summary'siz girişte de (push notification)
    // organizatör adı/avatarı görünür.
    final ride = state.ride;
    final name =
        ride?.organizerName ?? summary?.organizerName ?? 'Organizatör';
    final avatar = ride?.organizerAvatarUrl ?? summary?.organizerAvatarUrl;
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
          backgroundImage: hasAvatar
              ? CachedNetworkImageProvider(avatar.toAbsoluteImageUrl())
              : null,
          child: hasAvatar
              ? null
              : Text(
                  _initials(name),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organizatör',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DefaultTextStyle.merge(
          style: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ParticipantsSection extends StatelessWidget {
  final List<ParticipantEntity> participants;
  const _ParticipantsSection({required this.participants});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Katılımcılar (${participants.length})',
      child: Column(
        children: participants
            .map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _ParticipantTile(participant: p),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final ParticipantEntity participant;
  const _ParticipantTile({required this.participant});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = _participantName(participant);
    final avatar = participant.profileImageUrl;
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
          backgroundImage: hasAvatar
              ? CachedNetworkImageProvider(avatar.toAbsoluteImageUrl())
              : null,
          child: hasAvatar
              ? null
              : Text(
                  _initials(name),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingRequestsSection extends StatelessWidget {
  final List<ParticipantEntity> participants;
  final bool actionInProgress;
  const _PendingRequestsSection({
    required this.participants,
    required this.actionInProgress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Section(
      title: 'Bekleyen istekler (${participants.length})',
      child: Column(
        children: participants.map((p) {
          final name = _participantName(p);
          final avatar = p.profileImageUrl;
          final hasAvatar = avatar != null && avatar.isNotEmpty;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                  backgroundImage: hasAvatar
                      ? CachedNetworkImageProvider(avatar.toAbsoluteImageUrl())
                      : null,
                  child: hasAvatar
                      ? null
                      : Text(
                          _initials(name),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Onayla',
                  onPressed: actionInProgress
                      ? null
                      : () => context.read<RideDetailBloc>().add(
                          ParticipantApproved(p.userId),
                        ),
                  icon: Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green,
                  ),
                ),
                IconButton(
                  tooltip: 'Reddet',
                  onPressed: actionInProgress
                      ? null
                      : () => context.read<RideDetailBloc>().add(
                          ParticipantRejected(p.userId),
                        ),
                  icon: Icon(
                    Icons.cancel_outlined,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alt aksiyon barı
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final RideDetailState state;
  const _ActionBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final busy = state.actionInProgress;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: _buildContent(context, colorScheme, busy),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    bool busy,
  ) {
    if (state.isOrganizer) {
      return FilledButton.icon(
        onPressed: () => _openManage(context),
        icon: const Icon(Icons.settings_rounded),
        label: const Text('Turu Yönet'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
        ),
      );
    }

    if (state.isApprovedMember) {
      return Row(
        children: [
          Expanded(
            child: _statusPill(
              colorScheme,
              icon: Icons.check_circle_rounded,
              text: 'Katıldın',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: busy ? null : () => _confirmLeave(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 50),
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
            ),
            child: const Text('Ayrıl'),
          ),
        ],
      );
    }

    if (state.isPending) {
      return Row(
        children: [
          Expanded(
            child: _statusPill(
              colorScheme,
              icon: Icons.hourglass_top_rounded,
              text: 'Onay bekleniyor',
              color: colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: busy
                ? null
                : () => context.read<RideDetailBloc>().add(
                    const LeaveRequested(),
                  ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 50),
            ),
            child: const Text('İsteği geri çek'),
          ),
        ],
      );
    }

    if (state.isRejected) {
      return _statusPill(
        colorScheme,
        icon: Icons.block_rounded,
        text: 'Katılma isteğin reddedildi',
        color: colorScheme.error,
        fullWidth: true,
      );
    }

    // canJoin — henüz katılmamış kullanıcı.
    final ride = state.ride!;
    final isFull = ride.maxParticipants > 0 &&
        state.approvedParticipants.length >= ride.maxParticipants;
    if (isFull) {
      return _statusPill(
        colorScheme,
        icon: Icons.group_off_rounded,
        text: 'Kontenjan dolu',
        color: colorScheme.outline,
        fullWidth: true,
      );
    }

    // Daha önce ayrılmış/geri çekmiş kullanıcı tekrar katılabilir → "Tekrar katıl".
    final rejoining = state.myStatus == 'Left';
    return FilledButton.icon(
      onPressed: busy ? null : () => _confirmJoin(context),
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(rejoining ? Icons.refresh_rounded : Icons.add_rounded),
      label: Text(
        busy ? 'Gönderiliyor...' : (rejoining ? 'Tekrar katıl' : 'Katıl'),
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }

  Widget _statusPill(
    ColorScheme colorScheme, {
    required IconData icon,
    required String text,
    required Color color,
    bool fullWidth = false,
  }) {
    final pill = Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: pill) : pill;
  }

  Future<void> _confirmJoin(BuildContext context) async {
    final bloc = context.read<RideDetailBloc>();
    // Controller dialog'un kendi State'inde yaşar; route tamamen kalkınca
    // framework dispose eder (await sonrası senkron dispose → "used after
    // disposed" hatasına yol açıyordu). Vazgeç → null, Katıl → (boş olabilen) mesaj.
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const _JoinMessageDialog(),
    );
    if (result == null) return;
    final msg = result.trim();
    bloc.add(JoinRequested(message: msg.isEmpty ? null : msg));
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final bloc = context.read<RideDetailBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turdan ayrıl'),
        content: const Text('Bu turdan ayrılmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ayrıl'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(const LeaveRequested());
    }
  }

  void _openManage(BuildContext context) {
    final ride = state.ride!;
    context.push(
      '/communication/group-page/${ride.id}',
      extra: GroupRideArgs(
        rideId: ride.id,
        sessionId: ride.sessionId,
        groupName: ride.title,
        maxParticipants: ride.maxParticipants,
        destination: ride.endLocation,
        ridingStyle: ride.ridingStyle,
        description: ride.description,
        difficulty: ride.difficulty,
        startDateTime: ride.startDateTime,
        endDateTime: ride.endDateTime,
        startLocation: ride.startLocation,
        endLocation: ride.endLocation,
        startLatitude: ride.startLatitude,
        startLongitude: ride.startLongitude,
        endLatitude: ride.endLatitude,
        endLongitude: ride.endLongitude,
        organizerId: ride.adminId,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Katılım mesajı dialog'u
// ─────────────────────────────────────────────────────────────────────────────

/// Katılma mesajı dialog'u. Controller'ı kendi State'i sahiplenir → framework,
/// route tamamen kaldırıldıktan sonra dispose eder (await sonrası senkron
/// dispose'un "used after disposed" hatasını önler).
/// Sonuç: Vazgeç → null pop; Katıl → (boş olabilen) mesaj metni.
class _JoinMessageDialog extends StatefulWidget {
  const _JoinMessageDialog();

  @override
  State<_JoinMessageDialog> createState() => _JoinMessageDialogState();
}

class _JoinMessageDialogState extends State<_JoinMessageDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tura katıl'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('İstersen organizatöre kısa bir mesaj bırakabilirsin.'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 2,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'Mesaj (opsiyonel)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Katıl'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yardımcılar
// ─────────────────────────────────────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  final String? difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final d = difficulty ?? '';
    final ({String label, Color color}) v = switch (d) {
      'Beginner' => (label: 'Başlangıç', color: Colors.green),
      'Intermediate' => (label: 'Orta', color: Colors.orange),
      'Advanced' => (label: 'İleri', color: Colors.deepOrange),
      'Expert' => (label: 'Uzman', color: Colors.red),
      _ => (label: d.isEmpty ? '—' : d, color: Theme.of(context).colorScheme.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: v.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: v.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        v.label,
        style: TextStyle(
          color: v.color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      ),
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

const _months = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

String _formatFullDate(DateTime d) {
  final local = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.day} ${_months[local.month - 1]} ${local.year} · '
      '${two(local.hour)}:${two(local.minute)}';
}

String _durationLabel(int minutes) {
  if (minutes < 60) return '$minutes dk';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h sa' : '$h sa $m dk';
}

String _styleLabel(String? raw) => switch (raw) {
  'Sakin' => 'Sakin',
  'Tour' => 'Tur',
  'Viraj' => 'Viraj',
  'Sehir' => 'Şehir',
  _ => raw ?? '—',
};
