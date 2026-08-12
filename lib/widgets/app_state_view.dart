import 'package:flutter/material.dart';

/// حالات واجهة موحّدة للتحميل والفراغ والخطأ في شاشات Task Flow.
///
/// تحافظ هذه المكونات على اتجاه RTL وهوية التطبيقات الحضرية، وتعرض
/// سياقًا واضحًا بدل شاشة فارغة أو رسالة تقنية مقتضبة.
class AppLoadingState extends StatelessWidget {
  final String? label;

  const AppLoadingState({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(label!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: icon,
      title: title,
      message: message,
      accentColor: Theme.of(context).colorScheme.primary,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: Icons.cloud_off_outlined,
      title: title,
      message: message,
      accentColor: Theme.of(context).colorScheme.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _StateLayout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateLayout({
    required this.icon,
    required this.title,
    required this.message,
    required this.accentColor,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: accentColor, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
