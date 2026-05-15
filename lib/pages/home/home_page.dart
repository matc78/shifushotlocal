import 'package:flutter/material.dart';
import 'package:shifushotlocal/pages/auth/guest_prompt.dart';
import 'package:shifushotlocal/state/guest_session.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isGuest = GuestSession.instance.isGuest;

    return Scaffold(
      body: PartyBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(isGuest: isGuest),
                const SizedBox(height: 8),
                if (isGuest) ...[
                  _GuestBanner(theme: theme),
                  const SizedBox(height: 12),
                ],
                const Spacer(),
                Text(
                  'WELCOME TO',
                  textAlign: TextAlign.center,
                  style: theme.overline.copyWith(color: theme.textMuted),
                ),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (rect) =>
                      theme.brandGradient.createShader(rect),
                  child: Text(
                    'SHIFUSHOT',
                    textAlign: TextAlign.center,
                    style: theme.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: theme.glowShadow,
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 230,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const Spacer(),
                GradientButton(
                  label: 'Lancer une partie',
                  icon: Icons.sports_esports_rounded,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/select_game'),
                ),
                const SizedBox(height: 12),
                const GhostButton(
                  label: 'Soon — Mode soirée',
                  icon: Icons.nightlife_rounded,
                  onPressed: null,
                ),
                const SizedBox(height: 24),
                _BottomActions(isGuest: isGuest),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isGuest});
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'HOME',
          style: theme.overline.copyWith(color: theme.textMuted),
        ),
        Row(
          children: [
            _IconChip(
              icon: Icons.notifications_none_rounded,
              onTap: () => Navigator.pushNamed(context, '/feedback_page'),
            ),
            const SizedBox(width: 10),
            _IconChip(
              icon: isGuest ? Icons.person_outline : Icons.person,
              highlight: !isGuest,
              onTap: () {
                if (isGuest) {
                  promptToSignUp(
                    context,
                    reason:
                        'Crée un compte pour personnaliser ton profil et garder tes stats.',
                  );
                } else {
                  Navigator.pushNamed(context, '/user_profile_page');
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: highlight ? theme.primary : theme.border,
            width: 1.2,
          ),
        ),
        child: Icon(icon, color: theme.textPrimary, size: 22),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.isGuest});
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BottomAction(
          icon: Icons.feedback_outlined,
          label: 'Feedback',
          onTap: () => Navigator.pushNamed(context, '/feedback_page'),
        ),
        _BottomAction(
          icon: Icons.group_rounded,
          label: 'Amis',
          locked: isGuest,
          onTap: () {
            if (isGuest) {
              promptToSignUp(
                context,
                reason:
                    "La liste d'amis n'est disponible qu'avec un compte.",
              );
              return;
            }
            Navigator.pushNamed(context, '/friends');
          },
        ),
        _BottomAction(
          icon: Icons.celebration_rounded,
          label: 'Soirée',
          onTap: () => Navigator.pushNamed(context, '/party_screen'),
        ),
      ],
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final color = theme.textPrimary;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: onTap,
      child: Opacity(
        opacity: locked ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.border),
                ),
                child: Icon(locked ? Icons.lock_outline : icon, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.bodyMedium.copyWith(
                  color: theme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: theme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: theme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mode invité — jeux locaux uniquement',
              style: theme.bodyMedium.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => promptToSignUp(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Créer un compte',
              style: theme.bodyMedium.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
