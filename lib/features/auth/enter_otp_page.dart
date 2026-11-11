import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/primary_button.dart';
import 'widgets/auth_landscape_footer.dart';
import 'widgets/auth_secure_banner.dart';

class EnterOtpPage extends StatefulWidget {
  const EnterOtpPage({
    required this.identifier,
    required this.type,
    super.key,
  });

  final String identifier;
  final String type;

  static const otpLength = 6;
  static const resendSeconds = 30;

  @override
  State<EnterOtpPage> createState() => _EnterOtpPageState();
}

class _EnterOtpPageState extends State<EnterOtpPage> {
  final _otpControllers = List.generate(
    EnterOtpPage.otpLength,
    (_) => TextEditingController(),
  );
  final _focusNodes = List.generate(
    EnterOtpPage.otpLength,
    (_) => FocusNode(),
  );

  bool _isLoading = false;
  int _secondsLeft = EnterOtpPage.resendSeconds;
  String _otpValue = '';
  Timer? _timer;

  bool get _isMobile => widget.type != 'E';
  bool get _canResend => _secondsLeft <= 0;
  bool get _canVerify => _otpValue.length == EnterOtpPage.otpLength;

  String get _formattedDestination {
    if (!_isMobile) return widget.identifier;
    final digits = widget.identifier.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return '+91 ${widget.identifier}';
    return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
  }

  String get _changeIdentifierLabel =>
      _isMobile ? 'Change Mobile Number' : 'Change Email Address';

  String get _resendLabel {
    if (_canResend) return 'Resend OTP';
    final seconds = _secondsLeft.toString().padLeft(2, '0');
    return 'Resend OTP (in 00:$seconds)';
  }

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    for (final controller in _otpControllers) {
      controller.addListener(_syncOtp);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncOtp() {
    setState(() {
      _otpValue = _otpControllers.map((controller) => controller.text).join();
    });
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = EnterOtpPage.resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      _pasteOtp(value);
      return;
    }

    if (value.isNotEmpty && index < EnterOtpPage.otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    _syncOtp();
  }

  void _pasteOtp(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < EnterOtpPage.otpLength; i++) {
      _otpControllers[i].text = i < digits.length ? digits[i] : '';
    }
    final focusIndex = digits.length.clamp(0, EnterOtpPage.otpLength - 1);
    _focusNodes[focusIndex].requestFocus();
    _syncOtp();
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await AppScope.of(context).session.requestOtp(
        identifier: widget.identifier,
        type: widget.type,
      );
      if (!mounted) return;
      if (!result.registered) {
        showAppMessage(context, 'Not registered', result.message);
        context.pop();
        return;
      }
      for (final controller in _otpControllers) {
        controller.clear();
      }
      _syncOtp();
      _focusNodes.first.requestFocus();
      _startResendTimer();
      showAppMessage(context, 'OTP sent', result.message);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Unable to resend OTP', error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_canVerify || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final user = await AppScope.of(context).session.verifyOtp(
        identifier: widget.identifier,
        otp: _otpValue,
        type: widget.type,
      );
      if (!mounted) return;
      showAppMessage(
        context,
        'Login successful',
        'Welcome${user.displayName == 'Admin' ? '' : ', ${user.firstName}'}.',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Unable to verify OTP', error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: () => context.pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: responsive.space(8, 12)),
                            Text(
                              'Enter OTP',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w800,
                                    fontSize: responsive.isCompactWidth
                                        ? 28
                                        : 32,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'We have sent a 6-digit OTP to $_formattedDestination',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: responsive.isCompactWidth ? 14 : 15,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: responsive.space(24, 30)),
                            const Text(
                              'Enter OTP',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _OtpBoxes(
                              controllers: _otpControllers,
                              focusNodes: _focusNodes,
                              onChanged: _onOtpChanged,
                            ),
                            SizedBox(height: responsive.space(18, 22)),
                            Center(
                              child: TextButton(
                                onPressed: _canResend ? _resendOtp : null,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.brand,
                                  disabledForegroundColor:
                                      AppColors.textSecondary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _resendLabel,
                                  style: TextStyle(
                                    decoration: _canResend
                                        ? TextDecoration.underline
                                        : TextDecoration.none,
                                    decorationColor: AppColors.brand,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () => context.pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.brand,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _changeIdentifierLabel,
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.brand,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: responsive.space(18, 24)),
                            const AuthSecureBanner(),
                            SizedBox(height: responsive.space(18, 24)),
                            PrimaryButton(
                              label: 'Verify OTP',
                              isLoading: _isLoading,
                              onPressed: _canVerify ? _verifyOtp : null,
                            ),
                            SizedBox(height: 12 + bottomInset),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              AuthLandscapeFooter(
                height: responsive.isShortHeight ? 96 : 120,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final isNarrow = AppResponsive.of(context).isCompactWidth;
    final boxSize = isNarrow ? 44.0 : 48.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = isNarrow ? 6.0 : 8.0;
        final totalGaps = gap * (EnterOtpPage.otpLength - 1);
        final available = constraints.maxWidth - totalGaps;
        final size = (available / EnterOtpPage.otpLength).clamp(40.0, boxSize);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(EnterOtpPage.otpLength, (index) {
            return SizedBox(
              width: size,
              height: size + 4,
              child: TextField(
                controller: controllers[index],
                focusNode: focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                onChanged: (value) => onChanged(index, value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.brand,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
