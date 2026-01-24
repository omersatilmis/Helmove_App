import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/text_styles.dart';
import 'package:go_router/go_router.dart';

class CreateJotsPage extends StatefulWidget {
  const CreateJotsPage({super.key});

  @override
  State<CreateJotsPage> createState() => _CreateJotsPageState();
}

class _CreateJotsPageState extends State<CreateJotsPage> {
  final TextEditingController _controller = TextEditingController();
  
  /// 1. FocusNode tanımladık
  final FocusNode _focusNode = FocusNode(); 
  
  final ValueNotifier<bool> _canPostNotifier = ValueNotifier(false);
  final ValueNotifier<int> _charCountNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);

    /// 2. Sayfa çizildikten sonra küçük bir gecikmeyle klavyeyi açıyoruz
    /// Bu sayede sayfa geçiş animasyonu (push) takılmadan biter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        // Sayfa hala açıksa klavyeyi çağır
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  void _onTextChanged() {
    final length = _controller.text.length;
    final canPost = _controller.text.trim().isNotEmpty;
    
    if (_charCountNotifier.value != length) {
      _charCountNotifier.value = length;
    }
    if (_canPostNotifier.value != canPost) {
      _canPostNotifier.value = canPost;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose(); /// 3. Bellek sızıntısı olmasın diye node'u siliyoruz
    _canPostNotifier.dispose();
    _charCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leadingWidth: 80,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text("İptal",
              style: TextStyle(color: theme.colorScheme.onSurface)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ValueListenableBuilder<bool>(
              valueListenable: _canPostNotifier,
              builder: (context, canPost, child) {
                return ElevatedButton(
                  onPressed: canPost
                      ? () => context.pop(_controller.text.trim())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                  ),
                  child: const Text("Jotla",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TEXT AREA
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      AssetImage('assets/icons/ic_profile.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode, /// 4. Node'u buraya bağladık
                    autofocus: false, /// 5. Otomatik açılışı kapattık
                    minLines: 4,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: isTablet ? 20 : 18),
                    decoration: InputDecoration(
                      hintText: "Neler oluyor?",
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            /// TOOLBAR
            Row(
              children: [
                _toolIcon(Icons.image_outlined, theme),
                _toolIcon(Icons.gif_box_outlined, theme),
                _toolIcon(Icons.poll_outlined, theme),
                _toolIcon(Icons.location_on_outlined, theme),
                const Spacer(),
                ValueListenableBuilder<int>(
                  valueListenable: _charCountNotifier,
                  builder: (context, count, child) {
                    return Text(
                      "$count/280",
                      style: TextStyle(
                        color: count > 250 ? Colors.red : Colors.grey,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolIcon(IconData icon, ThemeData theme) {
    return IconButton(
      splashRadius: 22,
      onPressed: () {},
      icon: Icon(icon, color: theme.colorScheme.primary, size: 24),
    );
  }
}