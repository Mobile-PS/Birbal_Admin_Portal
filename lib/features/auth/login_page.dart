import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/primary_button.dart';
import 'widgets/auth_secure_banner.dart';

enum LoginIdentifierType { mobile, email }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  LoginIdentifierType _identifierType = LoginIdentifierType.mobile;
  bool _isLoading = false;
  String _phoneDigits = '';
  String _emailValue = '';

  bool get _isMobile => _identifierType == LoginIdentifierType.mobile;

  bool get _canSendOtp {
    if (_isMobile) {
      return RegExp(r'^[6-9]\d{9}$').hasMatch(_phoneDigits);
    }
    return _isValidEmail(_emailValue);
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() => _phoneDigits = _phoneController.text.trim());
    });
    _emailController.addListener(() {
      setState(() => _emailValue = _emailController.text.trim());
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _selectType(LoginIdentifierType type) {
    if (_identifierType == type) return;
    setState(() {
      _identifierType = type;
      _formKey.currentState?.reset();
    });
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (!_isValidEmail(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _sendOtp() async {
    if (!_canSendOtp || _isLoading) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final type = _isMobile ? 'M' : 'E';
    final identifier = _isMobile
        ? _phoneController.text.trim()
        : _emailController.text.trim();

    setState(() => _isLoading = true);
    try {
      final result = await AppScope.of(context).session.requestOtp(
        identifier: identifier,
        type: type,
      );
      if (!mounted) return;
      if (!result.registered) {
        showAppMessage(context, 'Not registered', result.message);
        return;
      }
      showAppMessage(context, 'OTP sent', result.message);
      context.push(
        '/login/otp?identifier=${Uri.encodeComponent(identifier)}&type=$type',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      final lower = error.message.toLowerCase();
      final title = lower.contains('not registered')
          ? 'Not registered'
          : 'Unable to send OTP';
      showAppMessage(context, title, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafe = responsive.viewPadding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ResponsiveContent(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        responsive.horizontalPadding,
                        8,
                        responsive.horizontalPadding,
                        12,
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 12,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: responsive.space(8, 12)),
                              Text(
                                _isMobile
                                    ? 'Verify your\nMobile number'
                                    : 'Verify your\nEmail address',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                      fontSize: responsive.isCompactWidth
                                          ? 28
                                          : 32,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _isMobile
                                    ? "We'll send you a 6-digit OTP to verify your number."
                                    : "We'll send you a 6-digit OTP to verify your email.",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: responsive.isCompactWidth
                                      ? 14
                                      : 15,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: responsive.space(18, 22)),
                              _LoginTypeToggle(
                                selected: _identifierType,
                                onSelected: _selectType,
                              ),
                              SizedBox(height: responsive.space(18, 22)),
                              Text(
                                _isMobile
                                    ? 'Enter mobile number'
                                    : 'Enter email address',
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_isMobile)
                                TextFormField(
                                  key: const ValueKey('login-mobile'),
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.telephoneNumber,
                                  ],
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  onFieldSubmitted: (_) => _sendOtp(),
                                  decoration: _mobileDecoration(),
                                  validator: _validatePhone,
                                )
                              else
                                TextFormField(
                                  key: const ValueKey('login-email'),
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.email],
                                  onFieldSubmitted: (_) => _sendOtp(),
                                  decoration: _emailDecoration(),
                                  validator: _validateEmail,
                                ),
                              SizedBox(height: responsive.space(18, 22)),
                              PrimaryButton(
                                label: 'Send OTP',
                                isLoading: _isLoading,
                                onPressed: _canSendOtp ? _sendOtp : null,
                              ),
                              SizedBox(height: responsive.space(18, 24)),
                              const AuthSecureBanner(),
                              SizedBox(height: 12 + bottomInset),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _VerifyHero(bottomInset: bottomSafe),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginTypeToggle extends StatelessWidget {
  const _LoginTypeToggle({
    required this.selected,
    required this.onSelected,
  });

  final LoginIdentifierType selected;
  final ValueChanged<LoginIdentifierType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeChip(
              label: 'Mobile number',
              selected: selected == LoginIdentifierType.mobile,
              onTap: () => onSelected(LoginIdentifierType.mobile),
            ),
          ),
          Expanded(
            child: _TypeChip(
              label: 'Email',
              selected: selected == LoginIdentifierType.email,
              onTap: () => onSelected(LoginIdentifierType.email),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brand : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _mobileDecoration() {
  return InputDecoration(
    hintText: 'Enter mobile number',
    hintStyle: const TextStyle(color: Color(0xFF9AA6B2)),
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    prefixIcon: const Padding(
      padding: EdgeInsets.only(left: 16, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+91',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 10),
          SizedBox(
            height: 22,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.line,
            ),
          ),
          SizedBox(width: 4),
        ],
      ),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
    ),
  );
}

InputDecoration _emailDecoration() {
  return InputDecoration(
    hintText: 'Enter email address',
    hintStyle: const TextStyle(color: Color(0xFF9AA6B2)),
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    prefixIcon: const Icon(
      Icons.mail_outline_rounded,
      color: AppColors.textSecondary,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
    ),
  );
}

class _VerifyHero extends StatelessWidget {
  const _VerifyHero({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final heroHeight = responsive.isShortHeight ? 150.0 : 190.0;

    return SizedBox(
      height: heroHeight + bottomInset,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _SoftLandscapePainter()),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 4,
            child: Image.asset(
              AppAssets.verifyMobileCharacter,
              height: responsive.isShortHeight ? 120 : 150,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftLandscapePainter extends CustomPainter {
  const _SoftLandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, sky);

    final hill = Paint()..color = const Color(0xFFD9E8DF);
    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.35,
        size.width * 0.5,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.7,
        size.width,
        size.height * 0.48,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, hill);

    final tree = Paint()..color = const Color(0xFFC5DAC9);
    void mound(double cx, double cy, double r) {
      canvas.drawCircle(Offset(cx, cy), r, tree);
    }

    mound(size.width * 0.12, size.height * 0.48, 18);
    mound(size.width * 0.28, size.height * 0.42, 26);
    mound(size.width * 0.72, size.height * 0.5, 22);
    mound(size.width * 0.88, size.height * 0.44, 28);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
