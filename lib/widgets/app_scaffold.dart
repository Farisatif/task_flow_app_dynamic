import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme_provider.dart';
import 'app_bottom_nav.dart';

/// إطار موحّد لكل الشاشات: شريط علوي + محتوى + شريط تنقل سفلي اختياري
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int navIndex;
  final bool showNav;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? leading;
  final bool centerTitle;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.navIndex = -1,
    this.showNav = true,
    this.actions,
    this.floatingActionButton,
    this.leading,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBody: showNav,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: leading,
          automaticallyImplyLeading: leading != null,
          titleSpacing: leading == null ? 16 : 0,
          centerTitle: centerTitle,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.colorScheme.onSurface,
          title: title.isEmpty
              ? null
              : Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
          actions: [
            if (actions != null) ...actions!,
            IconButton(
              tooltip: 'تبديل الوضع الليلي',
              icon: Icon(
                themeProvider.isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              onPressed: () => themeProvider.toggle(),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          top: false,
          child: body,
        ),
        bottomNavigationBar:
            showNav && navIndex >= 0 ? AppBottomNav(currentIndex: navIndex) : null,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
