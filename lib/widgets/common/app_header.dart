import 'package:flutter/material.dart';
import '../../app/theme.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onProfilePressed;
  final List<Widget>? actions;
  final bool showBackButton;

  const AppHeader({
    super.key,
    this.title,
    this.onMenuPressed,
    this.onProfilePressed,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: VerTheme.primaryGreen,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Voltar',
                )
              else if (onMenuPressed != null)
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                  onPressed: onMenuPressed,
                  tooltip: 'Menu',
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'V.E.R.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      title ?? 'Visão Estratégica de Recursos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              ...?actions,
              if (onProfilePressed != null)
                IconButton(
                  icon: const CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: VerTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  onPressed: onProfilePressed,
                  tooltip: 'Perfil',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
