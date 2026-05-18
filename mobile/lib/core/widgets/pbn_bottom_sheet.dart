import 'package:flutter/material.dart';
import 'package:pbn/core/constants/app_colors.dart';

/// Standard chrome for every modal bottom sheet in PBN.
///
/// Provides:
///   • rounded top corners (28 radius)
///   • a 38×4 drag handle below the top edge
///   • max-height cap (88% of screen by default)
///   • safe-area-aware bottom padding
///   • optional keyboard inset handling for sheets with text fields
///
/// In the common case ([scrollable] = true, the default), the body is
/// wrapped in a [SingleChildScrollView] with horizontal page padding so
/// callers only need to provide a [Column] of hero + sections.
///
/// For sheets that need to manage their own internal layout — e.g. a
/// comment list with a sticky bottom input — pass [scrollable] = false
/// and the child fills the remaining vertical space below the drag
/// handle. Those callers are responsible for their own scroll and
/// keyboard handling inside.
class PbnBottomSheet extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final double maxHeightFraction;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final bool resizeForKeyboard;

  const PbnBottomSheet({
    super.key,
    required this.child,
    this.scrollable = true,
    this.maxHeightFraction = 0.88,
    this.horizontalPadding = 20,
    // Tight gap between the drag handle and the first body element.
    // A larger value creates a visible white "lip" above the navy hero
    // card inside the sheet, which reads as two stacked rounded layers
    // ("double roof"). Keeping this tight makes the sheet top and the
    // hero feel like one cohesive header.
    this.topPadding = 6,
    this.bottomPadding = 20,
    this.resizeForKeyboard = false,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardInset = resizeForKeyboard ? media.viewInsets.bottom : 0.0;

    final dragHandle = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );

    final body = scrollable
        ? Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                bottomPadding + media.padding.bottom,
              ),
              child: child,
            ),
          )
        : Expanded(child: child);

    return Container(
      constraints: BoxConstraints(
        maxHeight: media.size.height * maxHeightFraction,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Column(
        mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
        children: [
          dragHandle,
          body,
        ],
      ),
    );
  }
}

/// Show a [PbnBottomSheet] with the canonical `showModalBottomSheet`
/// defaults (transparent backdrop, scroll-controlled). Prefer this over
/// calling `showModalBottomSheet` directly so every sheet shares the
/// same chrome.
///
/// The scrim is tinted with the brand navy at 0.62 alpha rather than
/// Material's default 54% black. Reason: the background screens often
/// have gold-bar section headers and gold CTA buttons that bleed through
/// the lighter default scrim and visually compete with the sheet's own
/// section headers, creating a confusing "double bar" effect. A tinted,
/// slightly darker scrim pushes the background fully into the
/// background.
Future<T?> showPbnBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool useRootNavigator = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.primary.withValues(alpha: 0.62),
    useRootNavigator: useRootNavigator,
    showDragHandle: false,
    builder: builder,
  );
}
