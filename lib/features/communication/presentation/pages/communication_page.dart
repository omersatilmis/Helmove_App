import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../voice_session/presentation/bloc/voice_session_bloc.dart';
import '../../../voice_session/presentation/bloc/voice_session_event.dart';
import '../../../voice_session/presentation/bloc/voice_session_state.dart';
import '../widgets/active_session_card.dart';
import '../widgets/nearby_group.dart';

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({super.key});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  @override
  void initState() {
    super.initState();
    // İlk yükleme: BLoC zaten debounce transformer ile throttle yapıyor
    context.read<VoiceSessionBloc>().add(const GetMyVoiceSessionsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pendingInviteCount = context.select<VoiceSessionBloc, int>(
      (bloc) => bloc.state.pendingInvitesCount,
    );

    // Dinamik arka plan gradyanı
    final backgroundGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A100A), // Koyu modda hafif kırmızımsı üst
              Color(0xFF12100E),
            ],
            stops: [0.0, 0.4],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.surface,
              colorScheme.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          );

    return Container(
      decoration: BoxDecoration(gradient: backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: BlocListener<VoiceSessionBloc, VoiceSessionState>(
            listenWhen: (prev, curr) {
              final prevActiveId = prev.activeSession?.id;
              final currActiveId = curr.activeSession?.id;
              // Trigger detail fetch if active session changed OR if it's the same but details (session entity) are missing
              return prevActiveId != currActiveId ||
                  (currActiveId != null && curr.session?.id != currActiveId);
            },
            listener: (context, state) {
              final activeSession = state.activeSession;
              if (activeSession != null &&
                  state.session?.id != activeSession.id &&
                  state.status != VoiceSessionStatus.loading) {
                context.read<VoiceSessionBloc>().add(
                  GetVoiceSessionDetailsEvent(activeSession.id),
                );
              }
            },
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<VoiceSessionBloc>().add(
                  const GetMyVoiceSessionsEvent(force: true),
                );
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. ÜST BUTONLAR (Saved Sessions & Create Ride) ---
                    Row(
                      children: [
                        // --- SAVED SESSIONS (Nötr Cam) ---
                        Expanded(
                          child: _buildTopButton(
                            context,
                            title: "Saved\nSessions",
                            icon: Icons.bookmark_border,
                            glassTint: colorScheme.onSurface,
                            iconColor: colorScheme.primary,
                            textColor: colorScheme.onSurface,
                            onTap: () {},
                          ),
                        ),

                        const SizedBox(width: 16),

                        // --- CREATE RIDE GROUP (Renkli Cam) ---
                        Expanded(
                          child: _buildTopButton(
                            context,
                            title: "Create Ride\nGroup",
                            icon: Icons.add,
                            glassTint: colorScheme.primary,
                            iconColor: isDark
                                ? colorScheme.primary
                                : colorScheme.onPrimary,
                            textColor: isDark
                                ? colorScheme.onSurface
                                : colorScheme.onPrimary,
                            onTap: () async {
                              final currentBloc = context
                                  .read<VoiceSessionBloc>();
                              if (currentBloc.state.activeSession != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Lütfen yeni bir grup oluşturmadan önce mevcut sürüşten ayrılın.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: colorScheme.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              await context.push(
                                '/communication/create-group-ride',
                              );
                              if (mounted) {
                                context.read<VoiceSessionBloc>().add(
                                  const GetMyVoiceSessionsEvent(force: true),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // --- 2. YOUR ACTIVE GROUP BAŞLIĞI & SOS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              color: colorScheme.onSurface,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Your Active Group",
                              style: AppTextStyles.h3.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: colorScheme.onSurface,
                                size: 20,
                              ),
                              tooltip: 'Refresh',
                              onPressed: () {
                                context.read<VoiceSessionBloc>().add(
                                  const GetMyVoiceSessionsEvent(force: true),
                                );
                              },
                            ),
                          ],
                        ),
                        // --- SOS Acil Durum Butonu ---
                        GestureDetector(
                          onTap: () {
                            debugPrint("SOS Gönderildi!");
                          },
                          child: Container(
                            width: 60,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.error,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.error.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "!SOS",
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (pendingInviteCount > 0) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.mark_email_unread_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$pendingInviteCount pending invite${pendingInviteCount > 1 ? 's' : ''}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/notifications'),
                              child: const Text('Open'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // --- 3. ACTIVE GROUP KARTI (VoiceSession'dan yüklenir) ---
                    const ActiveSessionCard(),

                    const SizedBox(height: 30),

                    // --- 4. NEARBY GROUPS BAŞLIĞI ---
                    Row(
                      children: [
                        Icon(
                          Icons.signal_cellular_alt,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Nearby Groups",
                          style: AppTextStyles.h3.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // --- 5. NEARBY GROUPS LİSTESİ (Dummy UI) ---
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NearbyGroupCard(
                            groupName: "Weekend Riders",
                            distance: "1.2 km",
                            currentParticipants: 3,
                            maxParticipants: 10,
                            signalStatus: "Strong",
                            onJoinPressed: () {},
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NearbyGroupCard(
                            groupName: "Mountain Tour",
                            distance: "5.4 km",
                            currentParticipants: 8,
                            maxParticipants: 12,
                            signalStatus: "Good",
                            onJoinPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    // --- 6. BOTTOM PADDING (for extendBody: true) ---
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Üst Buton Yardımcı Fonksiyon ---
  Widget _buildTopButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color glassTint,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 85,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: glassTint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: glassTint.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
