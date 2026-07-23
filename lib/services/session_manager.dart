import 'dart:async';

import 'package:doc_genie/common/app_client.dart';
import 'package:doc_genie/config/app_config.dart';
import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/services/secure_helper.dart';
import 'package:doc_genie/utils/navigator_utils.dart';
import 'package:flutter/material.dart';

/// Drives the fixed-length login session: a warning popup fires
/// [AppConfig.sessionWarnBefore] before the [AppConfig.sessionDuration] ends,
/// and the session auto-logs-out at expiry if the user doesn't extend it.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  Timer? _warnTimer;
  Timer? _expiryTimer;
  bool _dialogOpen = false;

  /// Absolute time the current session expires. Non-null only while a session
  /// is active (set on login/extend, cleared on logout).
  DateTime? _expiresAt;

  /// (Re)starts the 30-minute session. Call on login and after each extend.
  void start() {
    _expiresAt = DateTime.now().add(AppConfig.sessionDuration);
    // Persist so the timeout can be re-checked after a tab freeze/restore.
    SecureHelper.instance.saveSessionExpiry(_expiresAt!);
    _dismissDialog();
    _schedule();
  }

  void _schedule() {
    _warnTimer?.cancel();
    _expiryTimer?.cancel();
    final expiresAt = _expiresAt;
    if (expiresAt == null) return;
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _expire();
      return;
    }
    final warnIn = remaining - AppConfig.sessionWarnBefore;
    _warnTimer = Timer(
      warnIn.isNegative ? Duration.zero : warnIn,
      _showWarningDialog,
    );
    _expiryTimer = Timer(remaining, _expire);
  }

  /// Stops all timers, clears the session, and closes the popup if open.
  void cancel() {
    _warnTimer?.cancel();
    _expiryTimer?.cancel();
    _warnTimer = null;
    _expiryTimer = null;
    _expiresAt = null;
    SecureHelper.instance.clearSessionExpiry();
    _dismissDialog();
  }

  /// Re-validates the session when the app/tab returns to the foreground.
  /// Browser tabs pause in-memory timers while frozen/hidden, so real elapsed
  /// time must be re-checked against [_expiresAt]; if it has passed, log out.
  Future<void> resumeCheck() async {
    final expiresAt = _expiresAt;
    if (expiresAt == null) return; // no active in-app session
    if (DateTime.now().isAfter(expiresAt)) {
      await AppClient.instance.logout(expired: true);
    } else {
      _schedule(); // resync timers to the real remaining time
    }
  }

  void _dismissDialog() {
    if (_dialogOpen) {
      _dialogOpen = false;
      navigatorKey.currentState?.pop();
    }
  }

  Future<void> _showWarningDialog() async {
    if (_dialogOpen) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    _dialogOpen = true;
    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _SessionExpiryDialog(
        countdown: AppConfig.sessionWarnBefore,
        onExtend: _extend,
      ),
    );
    _dialogOpen = false;
  }

  Future<void> _extend() async {
    // Stop the expiry timer from firing while the refresh is in flight.
    _warnTimer?.cancel();
    _expiryTimer?.cancel();
    final ok = await AppClient.instance.refreshSession();
    if (ok) {
      start(); // reschedules timers and dismisses the dialog
    } else {
      await AppClient.instance.logout(expired: true);
    }
  }

  void _expire() {
    // Warning countdown elapsed with no action → sign the user out.
    AppClient.instance.logout(expired: true);
  }
}

class _SessionExpiryDialog extends StatefulWidget {
  const _SessionExpiryDialog({required this.countdown, required this.onExtend});

  final Duration countdown;
  final Future<void> Function() onExtend;

  @override
  State<_SessionExpiryDialog> createState() => _SessionExpiryDialogState();
}

class _SessionExpiryDialogState extends State<_SessionExpiryDialog> {
  late int _secondsLeft = widget.countdown.inSeconds;
  Timer? _ticker;
  bool _extending = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _formatted {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _onExtend() async {
    if (_extending) return;
    setState(() => _extending = true);
    await widget.onExtend();
    // On success the manager pops this dialog; if it's still around, reset.
    if (mounted) setState(() => _extending = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: ColorConstants.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: ColorConstants.warningColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: ColorConstants.warningColor,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Session Expiring',
                  style: AppTextStyles.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your session will expire in',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatted,
                  style: AppTextStyles.heading.copyWith(
                    color: ColorConstants.warningColor,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stay signed in to continue working, or you will be logged out automatically.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _extending ? null : _onExtend,
                    child: _extending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Stay Signed In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
