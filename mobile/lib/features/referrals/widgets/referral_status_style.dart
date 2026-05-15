import 'package:flutter/material.dart';
import 'package:pbn/core/constants/app_colors.dart';

/// Visual styling for a Referral status pill.
///
/// Returned by [referralStatusStyle]. Every color is derived from
/// [AppColors] — adding a new color here is a failure of this contract.
///
/// Used at three call sites across the redesigned Referrals feature:
///   - The status pill on the list cards in `my_referrals_page.dart`
///   - The status pill grid in `_ReferralDetailsSheet`
///   - The history timeline dots in `_ReferralDetailsSheet`
class ReferralStatusStyle {
  /// Canonical UI label (matches `Referral.statusLabel` from the model).
  final String label;

  /// Foreground — used for the dot at full strength and the pill text.
  final Color fg;

  /// Background fill of the pill.
  final Color bg;

  /// 1px border color of the pill.
  final Color border;

  /// Status dot color (currently equal to [fg], named separately so
  /// callers don't have to reason about which channel maps to what).
  final Color dot;

  const ReferralStatusStyle({
    required this.label,
    required this.fg,
    required this.bg,
    required this.border,
    required this.dot,
  });
}

/// Canonical status keys in pipeline order.
///
/// Iterate this list anywhere you need to render the full set of selectable
/// statuses (e.g. the edit grid in the Lead Details sheet). Defining a
/// separate local list of `{value, label}` pairs is what introduced the
/// "New / Discussing / Waiting" label drift in the original code — don't
/// do that again.
const List<String> referralStatusOrder = [
  'submitted',
  'contacted',
  'negotiation',
  'in_progress',
  'success',
  'closed_lost',
];

/// Returns the visual styling for a given Referral status string.
///
/// Mapping:
///   submitted / contacted     → accentBlue  (new intent, in-motion)
///   negotiation / in_progress → warning     (needs attention)
///   success                   → success     (closed-won)
///   closed_lost               → muted slate over surfaceAlt
///                               — NOT error red. The redesign skill reserves
///                               red for destructive UI, not for outcomes
///                               that didn't land.
///
/// Unknown status strings fall back to the muted style, so this function
/// is total — it never returns null and never throws.
ReferralStatusStyle referralStatusStyle(String status) {
  switch (status) {
    case 'submitted':
      return ReferralStatusStyle(
        label: 'Submitted',
        fg: AppColors.accentBlue,
        bg: AppColors.accentBlue.withValues(alpha: 0.12),
        border: AppColors.accentBlue.withValues(alpha: 0.30),
        dot: AppColors.accentBlue,
      );
    case 'contacted':
      return ReferralStatusStyle(
        label: 'Contacted',
        fg: AppColors.accentBlue,
        bg: AppColors.accentBlue.withValues(alpha: 0.12),
        border: AppColors.accentBlue.withValues(alpha: 0.30),
        dot: AppColors.accentBlue,
      );
    case 'negotiation':
      return ReferralStatusStyle(
        label: 'Negotiation',
        fg: AppColors.warning,
        bg: AppColors.warning.withValues(alpha: 0.12),
        border: AppColors.warning.withValues(alpha: 0.30),
        dot: AppColors.warning,
      );
    case 'in_progress':
      return ReferralStatusStyle(
        label: 'In Progress',
        fg: AppColors.warning,
        bg: AppColors.warning.withValues(alpha: 0.12),
        border: AppColors.warning.withValues(alpha: 0.30),
        dot: AppColors.warning,
      );
    case 'success':
      return ReferralStatusStyle(
        label: 'Success',
        fg: AppColors.success,
        bg: AppColors.success.withValues(alpha: 0.12),
        border: AppColors.success.withValues(alpha: 0.30),
        dot: AppColors.success,
      );
    case 'closed_lost':
      // Muted pill: outcome didn't land, but this isn't destructive UI.
      // Background uses surfaceAlt (not tint-at-0.12) so the state reads
      // as "inactive" rather than "another colored thing in the list".
      return ReferralStatusStyle(
        label: 'Lost',
        fg: AppColors.textMuted,
        bg: AppColors.surfaceAlt,
        border: AppColors.border,
        dot: AppColors.textMuted,
      );
    default:
      // Unknown status — humanize the raw value the same way the model
      // does in `Referral.statusLabel`, and use the muted style so
      // unfamiliar statuses can't impersonate a primary semantic colour.
      final fallbackLabel = status.isEmpty
          ? 'Unknown'
          : status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
      return ReferralStatusStyle(
        label: fallbackLabel,
        fg: AppColors.textMuted,
        bg: AppColors.surfaceAlt,
        border: AppColors.border,
        dot: AppColors.textMuted,
      );
  }
}
