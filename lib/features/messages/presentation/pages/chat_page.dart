import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../bloc/chat/chat_bloc.dart';
import '../bloc/chat/chat_event.dart';
import '../bloc/chat/chat_state.dart';
import 'call_page.dart';

class ChatPage extends StatelessWidget {
  final int otherUserId;
  final String firstName;
  final String lastName;
  final String username;
  final String? profileImageUrl;

  const ChatPage({
    super.key,
    required this.otherUserId,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChatBloc>()
        ..add(LoadMessages(otherUserId))
        ..add(MarkAsRead(otherUserId)),
      child: ChatView(
        otherUserId: otherUserId,
        firstName: firstName,
        lastName: lastName,
        username: username,
        profileImageUrl: profileImageUrl,
      ),
    );
  }
}

class ChatView extends StatefulWidget {
  final int otherUserId;
  final String firstName;
  final String lastName;
  final String username;
  final String? profileImageUrl;

  const ChatView({
    super.key,
    required this.otherUserId,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.profileImageUrl,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _controller.addListener(() {
      final isNotEmpty = _controller.text.trim().isNotEmpty;
      if (_isTyping != isNotEmpty) {
        setState(() => _isTyping = isNotEmpty);
        // Notify Bloc about typing status
        context.read<ChatBloc>().add(
          UpdateTypingStatus(
            targetUserId: widget.otherUserId,
            isTyping: isNotEmpty,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    context.read<ChatBloc>().add(
      SendMessageEvent(receiverId: widget.otherUserId, content: text),
    );

    _controller.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Refined Tones
    final Color appBarBg = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final Color scaffoldBg = isDark
        ? AppColors.darkBackground
        : AppColors.lightSurface;
    final Color inputAreaBg = isDark
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final Color inputFieldBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceContainer;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildAppBar(theme, appBarBg),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }

                if (state is ChatError) {
                  return Center(child: Text('Hata: ${state.message}'));
                }

                if (state is ChatLoaded) {
                  final messages = state.messages;

                  if (messages.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];

                      // SIMPLE & ROBUST ALIGNMENT:
                      // If it's NOT from the other person, it's from ME.
                      final bool isMe = message.senderId != widget.otherUserId;

                      final bool isFirstInGroup =
                          index == messages.length - 1 ||
                          messages[index + 1].senderId != message.senderId;

                      final bool isLastInGroup =
                          index == 0 ||
                          messages[index - 1].senderId != message.senderId;

                      bool showDate = false;
                      final DateTime localSentAt = message.sentAt.toLocal();

                      if (index == messages.length - 1) {
                        showDate = true;
                      } else {
                        final olderMessage = messages[index + 1];
                        if (!_isSameDay(
                          localSentAt,
                          olderMessage.sentAt.toLocal(),
                        )) {
                          showDate = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDate) _DateChip(date: localSentAt),
                          _MessageBubble(
                            text: message.content,
                            time: localSentAt,
                            isMe: isMe,
                            isRead: message.isRead,
                            isFirstInGroup: isFirstInGroup,
                            isLastInGroup: isLastInGroup,
                          ),
                        ],
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
          _buildInputArea(theme, inputAreaBg, inputFieldBg),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, Color bgColor) {
    final colorScheme = theme.colorScheme;
    return AppBar(
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 40,
      titleSpacing: 8,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primary.withValues(alpha:0.1),
            backgroundImage: widget.profileImageUrl != null
                ? CachedNetworkImageProvider(widget.profileImageUrl!)
                : null,
            child: widget.profileImageUrl == null
                ? Text(
                    widget.firstName[0].toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (previous, current) {
                if (previous is ChatLoaded && current is ChatLoaded) {
                  return previous.isOtherUserTyping !=
                      current.isOtherUserTyping;
                }
                return true;
              },
              builder: (context, state) {
                bool isTyping = false;
                if (state is ChatLoaded) {
                  isTyping = state.isOtherUserTyping;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.firstName} ${widget.lastName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isTyping ? 'yazıyor...' : 'çevrimiçi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isTyping
                            ? Colors.greenAccent
                            : colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontStyle: isTyping
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.call_outlined, color: colorScheme.primary, size: 22),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CallPage(
                  targetUserId: widget.otherUserId,
                  targetDisplayName: '${widget.firstName} ${widget.lastName}'
                      .trim(),
                  targetProfileImageUrl: widget.profileImageUrl,
                  isOutgoing: true,
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: colorScheme.primary,
            size: 22,
          ),
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          color: theme.dividerColor.withValues(alpha:0.05),
          height: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary.withValues(alpha:0.1)),
        ),
        child: Text(
          "🔒 Mesajlar uçtan uca şifrelidir. Bu sohbeti kimse okuyamaz veya dinleyemez.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, Color containerBg, Color fieldBg) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: containerBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: colorScheme.primary,
                        size: 26,
                      ),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Mesaj...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 11,
                          ),
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(alpha:
                              0.6,
                            ),
                          ),
                        ),
                        maxLines: 5,
                        minLines: 1,
                        style: theme.textTheme.bodyLarge,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha:0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isTyping ? Icons.send_rounded : Icons.mic_rounded,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

// Mesaj balonu
class _MessageBubble extends StatelessWidget {
  final String text;
  final DateTime time;
  final bool isMe;
  final bool isRead;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.isRead,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bubbleColor = isMe
        ? colorScheme.primary
        : (isDark ? const Color(0xFF383838) : Colors.white);

    final textColor = isMe
        ? colorScheme.onPrimary
        : (isDark ? Colors.white : colorScheme.onSurface);

    final timeColor = isMe
        ? colorScheme.onPrimary.withValues(alpha:0.7)
        : (isDark ? Colors.white70 : colorScheme.onSurfaceVariant);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
          minWidth: 60,
        ),
        margin: EdgeInsets.only(
          top: isFirstInGroup ? 4 : 1,
          bottom: 1,
          left: isMe ? 40 : 12,
          right: isMe ? 12 : 40,
        ),
        child: CustomPaint(
          painter: _BubblePainter(
            color: bubbleColor,
            isMe: isMe,
            showTail: isFirstInGroup,
            isDark: isDark,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMe ? 10 : (isFirstInGroup ? 18 : 10),
              5,
              isMe ? (isFirstInGroup ? 18 : 10) : 10,
              5,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, right: 10),
                  child: Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -1,
                  right: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(time),
                        style: TextStyle(
                          fontSize: 10,
                          color: timeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 3),
                        Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: isRead ? const Color(0xFF69F0AE) : colorScheme.onPrimary.withValues(alpha:0.6),
                        ),
                      ],
                    ],
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

// Bubbles with tails custom painter
class _BubblePainter extends CustomPainter {
  final Color color;
  final bool isMe;
  final bool showTail;
  final bool isDark;

  _BubblePainter({
    required this.color,
    required this.isMe,
    required this.showTail,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (isMe) {
      path.addRRect(
        RRect.fromLTRBAndCorners(
          0,
          0,
          size.width - (showTail ? 8 : 0),
          size.height,
          topLeft: const Radius.circular(16),
          bottomLeft: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
          topRight: showTail ? Radius.zero : const Radius.circular(16),
        ),
      );
      if (showTail) {
        path.moveTo(size.width - 8, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width - 8, 12);
        path.close();
      }
    } else {
      path.addRRect(
        RRect.fromLTRBAndCorners(
          showTail ? 8 : 0,
          0,
          size.width,
          size.height,
          topRight: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
          bottomLeft: const Radius.circular(16),
          topLeft: showTail ? Radius.zero : const Radius.circular(16),
        ),
      );
      if (showTail) {
        path.moveTo(8, 0);
        path.lineTo(0, 0);
        path.lineTo(8, 12);
        path.close();
      }
    }

    if (!isDark && !isMe) {
      canvas.drawShadow(path, Colors.black.withValues(alpha:0.2), 2, false);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Tarih chip
class _DateChip extends StatelessWidget {
  final DateTime date;
  const _DateChip({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withValues(alpha:0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _getDateLabel(date),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'BUGÜN';
    if (checkDate == yesterday) return 'DÜN';
    return DateFormat('d MMMM yyyy', 'tr_TR').format(date).toUpperCase();
  }
}
