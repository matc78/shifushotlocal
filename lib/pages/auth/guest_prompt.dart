import 'package:flutter/material.dart';
import 'package:shifushotlocal/state/guest_session.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

/// Shows a dialog inviting a guest user to create an account.
/// Returns true if the user chose to sign up (and was navigated to auth).
Future<bool> promptToSignUp(BuildContext context, {String? reason}) async {
  final theme = AppTheme.of(context);
  final accepted = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Connecte-toi pour continuer', style: theme.titleMedium),
      content: Text(
        reason ?? 'Cette fonctionnalité nécessite un compte ShiFuShot.',
        style: theme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Plus tard', style: theme.bodyMedium),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            'Créer un compte',
            style: theme.bodyMedium.copyWith(color: theme.buttonColor),
          ),
        ),
      ],
    ),
  );
  if (accepted == true && context.mounted) {
    GuestSession.instance.exitGuestMode();
    Navigator.of(context).pushNamedAndRemoveUntil('/debutpage', (route) => false);
    return true;
  }
  return false;
}
