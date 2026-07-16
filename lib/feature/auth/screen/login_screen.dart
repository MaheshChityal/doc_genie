import 'dart:math' as math;

import 'package:flutter/scheduler.dart';

import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/auth/controller/login_controller.dart';
import 'package:doc_genie/feature/auth/model/login_model.dart';
import 'package:doc_genie/feature/shell/screen/main_shell.dart';
import 'package:doc_genie/utils/navigator_utils.dart';
import 'package:doc_genie/utils/snackbar_utils.dart';
import 'package:doc_genie/utils/validators.dart';
import 'package:doc_genie/widgets/app_button.dart';
import 'package:doc_genie/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _empCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _empCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    ref
        .read(loginControllerProvider.notifier)
        .login(
          employeeCode: _empCodeController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GenericState>(loginControllerProvider, (previous, next) {
      if (next is LoadedState<LoginModel>) {
        navigateAndRemoveAll(context, const MainShell());
      } else if (next is ErrorState) {
        SnackBarUtils.show(
          next.exception.message,
          context: context,
          type: SnackType.error,
        );
      }
    });

    final state = ref.watch(loginControllerProvider);
    final isLoading = state is LoadingState;

    final form = _FormPanel(
      formKey: _formKey,
      empCodeController: _empCodeController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      isLoading: isLoading,
      onTogglePassword: () {
        setState(() => _obscurePassword = !_obscurePassword);
      },
      onSubmit: _submit,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0C1E30),
      body: Stack(
        children: [
          const Positioned.fill(child: _ScreenBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isWide ? 980 : 460),
                      child: _EntryAnimation(
                        child: isWide
                            ? IntrinsicHeight(
                                child: AppCard(
                                  padding: EdgeInsets.zero,
                                  borderColor: Colors.transparent,
                                  backgroundColor: Colors.transparent,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Expanded(
                                        flex: 5,
                                        child: _WelcomePanel(),
                                      ),
                                      Expanded(flex: 5, child: form),
                                    ],
                                  ),
                                ),
                              )
                            : AppCard(
                                padding: EdgeInsets.zero,
                                borderColor: Colors.transparent,
                                backgroundColor: Colors.transparent,
                                child: Column(
                                  children: [
                                    const _WelcomePanel(compact: true),
                                    form,
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryAnimation extends StatelessWidget {
  const _EntryAnimation({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: -80,
          left: -60,
          child: _BlurOrb(
            size: 260,
            colors: [Color(0x44183B5B), Color(0x00183B5B)],
          ),
        ),
        Positioned(
          right: -90,
          top: 80,
          child: _BlurOrb(
            size: 320,
            colors: [Color(0x441F7A6A), Color(0x001F7A6A)],
          ),
        ),
        Positioned(
          left: 20,
          bottom: -120,
          child: _BlurOrb(
            size: 300,
            colors: [Color(0x44F47B50), Color(0x00F47B50)],
          ),
        ),
      ],
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.08),
      duration: const Duration(milliseconds: 4200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ColorConstants.heroGradient),
      padding: EdgeInsets.all(compact ? 28 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BrandRow(),
          SizedBox(height: compact ? 22 : 34),
          Text(
            'Welcome Back',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 32 : 42,
              height: 1.02,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Scan, fill, and authorise banking documents — all in one place.',
            style: TextStyle(
              color: Color(0xD9FFFFFF),
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 30),
            const _Benefit(
              icon: Icons.upload_file_rounded,
              text: 'Upload & auto-scan documents',
            ),
            const SizedBox(height: 16),
            const _Benefit(
              icon: Icons.edit_document,
              text: 'Auto-fill RTGS, NEFT & Fund Transfer fields',
            ),
            const SizedBox(height: 16),
            const _Benefit(
              icon: Icons.send_rounded,
              text: 'Submit for checker review',
            ),
            const SizedBox(height: 16),
            const _Benefit(
              icon: Icons.verified_rounded,
              text: 'Approve & authorise payments',
            ),
          ],
        ],
      ),
    );
  }
}

class _ScreenBackdrop extends StatelessWidget {
  const _ScreenBackdrop();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: _screenGradient)),
        _Backdrop(),
        _AnimatedField(),
      ],
    );
  }
}

const LinearGradient _screenGradient = LinearGradient(
  colors: [Color(0xFF0C1E30), Color(0xFF14304A), Color(0xFF10333A)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class _AnimatedField extends StatefulWidget {
  const _AnimatedField();

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;

  static const _snippets = <String>[
    'RTGS: remitterAccount = "CASA-001"',
    'NEFT: beneIfscCode = "HDFC0001234"',
    'amount = 5000000.00 // ≥50Cr → LEI required',
    'chequeBasedTransaction = "With Cheque"',
    'transactionType = TransactionType.rtgs',
    'await scanDocument(file, mode: Auto)',
    'status = DocumentStatus.pendingReview',
    'checker.decide(id, Decision.approved)',
    'fundTransfer: beneAccount = "00123456789"',
    'narration = "Salary transfer Q3 2026"',
    'await submitDocument(documentId, fields)',
    'instructionPriority = "High"',
    'sendingInfo = "SMS"',
  ];

  static const _codeLines = <_CodeLine>[
    _CodeLine(15, 0.00, 15, 0.16, 0, 1),
    _CodeLine(19, 0.35, 13, 0.13, 3, 2),
    _CodeLine(12, 0.60, 14, 0.15, 6, 3),
    _CodeLine(22, 0.15, 16, 0.12, 9, 4),
    _CodeLine(17, 0.80, 13, 0.14, 1, 5),
    _CodeLine(25, 0.50, 15, 0.11, 4, 6),
    _CodeLine(14, 0.25, 13, 0.13, 7, 7),
  ];

  static const _glyphs = <_Glyph>[
    _Glyph(Icons.description_rounded, 48, 34, 0.05, 0.7, 12, 0.24, 11),
    _Glyph(Icons.account_balance_rounded, 52, 28, 0.40, 0.9, 14, 0.22, 12),
    _Glyph(Icons.receipt_long_rounded, 44, 40, 0.70, 0.6, 12, 0.20, 13),
    _Glyph(Icons.upload_file_rounded, 36, 26, 0.20, 1.1, 10, 0.20, 14),
    _Glyph(Icons.verified_rounded, 34, 32, 0.85, 0.8, 10, 0.18, 15),
    _Glyph(Icons.currency_rupee_rounded, 40, 38, 0.55, 0.6, 12, 0.18, 16),
    _Glyph(Icons.document_scanner_rounded, 42, 30, 0.10, 1.0, 12, 0.20, 17),
    _Glyph(Icons.send_rounded, 46, 36, 0.65, 0.9, 14, 0.22, 18),
    _Glyph(Icons.lock_rounded, 38, 24, 0.30, 1.0, 12, 0.20, 19),
    _Glyph(Icons.approval_rounded, 40, 44, 0.90, 0.7, 12, 0.18, 20),
    _Glyph(Icons.check_circle_rounded, 38, 33, 0.48, 0.8, 12, 0.18, 21),
    _Glyph(Icons.swap_horiz_rounded, 34, 29, 0.75, 1.1, 10, 0.16, 22),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _t = elapsed.inMicroseconds / 1e6);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  static double _hash(int n) {
    final v = math.sin(n * 12.9898) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              children: [
                for (final line in _codeLines) _buildCode(line, w, h),
                for (final g in _glyphs) _buildGlyph(g, w, h),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCode(_CodeLine line, double w, double h) {
    final progress = _t / line.period + line.phase;
    final p = progress - progress.floorToDouble();
    final cycle = progress.floor();
    final text = _snippets[(line.startIndex + cycle) % _snippets.length];
    final approxWidth = text.length * line.fontSize * 0.62;
    final x = -approxWidth + p * (w + approxWidth);
    final y = (0.05 + _hash(line.seed * 131 + cycle * 17) * 0.86) * h;
    return Positioned(
      left: x,
      top: y,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: line.fontSize,
          height: 1.0,
          color: Colors.white.withValues(alpha: line.opacity),
        ),
      ),
    );
  }

  Widget _buildGlyph(_Glyph g, double w, double h) {
    final progress = _t / g.period + g.phase;
    final p = progress - progress.floorToDouble();
    final cycle = progress.floor();
    final x = -g.size + p * (w + g.size);
    final bob = math.sin(_t * g.bobSpeed + g.phase * 6.2832) * g.bobAmp;
    final y = (0.05 + _hash(g.seed * 197 + cycle * 29) * 0.84) * h + bob;
    final angle = 0.22 * math.sin(_t * g.bobSpeed + g.phase * 6.2832);
    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: angle,
        child: Icon(
          g.icon,
          size: g.size,
          color: Colors.white.withValues(alpha: g.opacity),
        ),
      ),
    );
  }
}

class _CodeLine {
  const _CodeLine(
    this.period,
    this.phase,
    this.fontSize,
    this.opacity,
    this.startIndex,
    this.seed,
  );

  final double period;
  final double phase;
  final double fontSize;
  final double opacity;
  final int startIndex;
  final int seed;
}

class _Glyph {
  const _Glyph(
    this.icon,
    this.size,
    this.period,
    this.phase,
    this.bobSpeed,
    this.bobAmp,
    this.opacity,
    this.seed,
  );

  final IconData icon;
  final double size;
  final double period;
  final double phase;
  final double bobSpeed;
  final double bobAmp;
  final double opacity;
  final int seed;
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.document_scanner_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'DocGenie',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xF2FFFFFF),
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFFFFC9A8),
          size: 20,
        ),
      ],
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.formKey,
    required this.empCodeController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController empCodeController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorConstants.surface,
      padding: const EdgeInsets.all(32),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log In', style: AppTextStyles.heading),
            const SizedBox(height: 8),
            Text(
              'Enter your credentials to continue.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 26),
            Text(
              'Employee Code',
              style: AppTextStyles.title.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: empCodeController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              validator: Validators.employeeCode,
              decoration: const InputDecoration(
                hintText: 'e.g. M001 (Maker) or C001 (Checker)',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 18),
            Text('Password', style: AppTextStyles.title.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              validator: Validators.password,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            AppButton(
              label: 'Sign In  →',
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
