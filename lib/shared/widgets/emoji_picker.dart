import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

/// Curated emoji sets (no package needed). Keep in sync with frontend/src/components/EmojiPicker.tsx.
const emojiCategories = <(IconData, List<String>)>[
  (LucideIcons.smile, [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '😉', '😊', '😇', '🥰', '😍', '🤩', '😘',
    '😗', '😚', '😋', '😛', '😜', '🤪', '😝', '🤗', '🤭', '🤫', '🤔', '😐', '😑', '😶', '😏', '😌',
    '😴', '🥱', '😷', '🤒', '🤕', '🥴', '😵', '🥳', '😎', '🤓', '😕', '😟', '🙁', '😮', '😯', '😲',
    '😳', '🥺', '😦', '😧', '😨', '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞', '😓', '😩', '😫',
  ]),
  (LucideIcons.heart, [
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🤎', '🖤', '🤍', '💕', '💞', '💓', '💗', '💖', '💘', '💝',
    '💟', '❣️', '💔', '🫶', '🤲', '🙏', '👏', '🙌', '👍', '👎', '👌', '✌️', '🤞', '💪', '👋', '🤝',
  ]),
  (LucideIcons.baby, [
    '👶', '🍼', '🤱', '👩‍🍼', '🤰', '👪', '👨‍👩‍👧', '👨‍👩‍👦', '🧸', '🎀', '🧷', '🛁', '🛏️', '😴', '💤', '🌙',
    '⭐', '🌟', '✨', '🎈', '🎉', '🎂', '🎁', '🌸', '🌼', '🌻', '🌈', '☀️', '🦋', '🐣', '🐥', '🐻',
  ]),
  (LucideIcons.apple, [
    '🍎', '🍌', '🍉', '🍇', '🍓', '🥭', '🍍', '🥥', '🥝', '🍐', '🍊', '🍋', '🥑', '🥕', '🌽', '🥦',
    '🥔', '🍠', '🎃', '🥚', '🍚', '🍲', '🥣', '🥛', '🧃', '🍯', '🍪', '🧁', '🍰', '🍞', '🧀', '🍗',
  ]),
];

/// Opens a Facebook-style emoji panel and inserts the tapped emoji into
/// [controller] at the cursor (the panel stays open for several taps).
Future<void> showEmojiPicker(BuildContext context, TextEditingController controller) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      barrierColor: Colors.black12,
      builder: (_) => _EmojiPanel(onPick: (e) => insertAtCursor(controller, e)),
    );

void insertAtCursor(TextEditingController c, String text) {
  final sel = c.selection;
  final start = sel.isValid ? sel.start : c.text.length;
  final end = sel.isValid ? sel.end : c.text.length;
  final next = c.text.replaceRange(start, end, text);
  c.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: start + text.length));
}

/// Small smiley icon button that opens the picker for [controller].
class EmojiButton extends StatelessWidget {
  const EmojiButton({super.key, required this.controller, this.size = 20});

  final TextEditingController controller;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'ইমোজি',
        visualDensity: VisualDensity.compact,
        onPressed: () {
          FocusScope.of(context).unfocus();
          showEmojiPicker(context, controller);
        },
        icon: Icon(LucideIcons.smilePlus, size: size, color: AppColors.gold),
      );
}

class _EmojiPanel extends StatefulWidget {
  const _EmojiPanel({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  State<_EmojiPanel> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<_EmojiPanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final emojis = emojiCategories[_tab].$2;
    return SafeArea(
      child: SizedBox(
        height: 300,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            for (var i = 0; i < emojiCategories.length; i++)
              IconButton(
                onPressed: () => setState(() => _tab = i),
                icon: Icon(emojiCategories[i].$1, size: 20, color: i == _tab ? AppColors.maroon : AppColors.grey400),
              ),
          ]),
          const Divider(height: 1),
          Expanded(
            child: GridView.count(
              crossAxisCount: 8,
              padding: const EdgeInsets.all(8),
              children: [
                for (final e in emojis)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => widget.onPick(e),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
