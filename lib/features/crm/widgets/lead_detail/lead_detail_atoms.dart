import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import 'lead_detail_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Generic card shell
// ─────────────────────────────────────────────────────────────────────────────
class LdCardShell extends StatelessWidget {
  final Widget child;
  final String? label;
  final Widget? labelTrailing;
  final EdgeInsets margin;
  final Color color;

  const LdCardShell({
    super.key,
    required this.child,
    this.label,
    this.labelTrailing,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.color = LdToken.card,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LdToken.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C1A22).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Row(
              children: [
                Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: LdToken.textLow,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                if (labelTrailing != null) labelTrailing!,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────────────────────────────────────────
class LdAvatar extends StatelessWidget {
  final Color color;
  final String initials;
  final double radius;

  const LdAvatar({
    super.key,
    required this.color,
    required this.initials,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.55,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Star rating
// ─────────────────────────────────────────────────────────────────────────────
class LdStarRating extends StatelessWidget {
  final int stars;
  final double size;

  const LdStarRating({super.key, required this.stars, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: i < stars ? LdToken.primary : const Color(0xFFCCCCCC),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag badge
// ─────────────────────────────────────────────────────────────────────────────
class LdTagBadge extends StatelessWidget {
  final LeadTag tag;

  const LdTagBadge({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tag.bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag.icon != null) ...[
            Icon(tag.icon!, size: 12, color: tag.textColor),
            const SizedBox(width: 4),
          ],
          Text(
            tag.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tag.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Due badge
// ─────────────────────────────────────────────────────────────────────────────
class LdDueBadge extends StatelessWidget {
  final String label;
  final Color color;

  const LdDueBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon text row (email, phone, location)
// ─────────────────────────────────────────────────────────────────────────────
class LdIconRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const LdIconRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: LdToken.textLow),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: LdToken.textMed),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Outline action button
// ─────────────────────────────────────────────────────────────────────────────
class LdOutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const LdOutlineButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: LdToken.primary.withValues(alpha: 0.24)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: LdToken.textHigh),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: LdToken.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filled action button
// ─────────────────────────────────────────────────────────────────────────────
class LdFilledButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const LdFilledButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [LdToken.primary, Color(0xFF7C5A92)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
