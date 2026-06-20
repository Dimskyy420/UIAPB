import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controller/auth_controller.dart';
import 'home.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with SingleTickerProviderStateMixin {
  // ─── Controllers & State ──────────────────────────────────────────────────
  final AuthController _authController = AuthController();
  final List<TextEditingController> _ctrl = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focus = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  int _secondsLeft = 300; // 5 menit
  Timer? _timer;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _startTimer();
    // Auto-focus box pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    for (final c in _ctrl) { c.dispose(); }
    for (final f in _focus) { f.dispose(); }
    super.dispose();
  }

  // ─── Timer ────────────────────────────────────────────────────────────────
  void _startTimer() {
    _secondsLeft = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 0) {
        t.cancel();
        setState(() {});
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _isExpired => _secondsLeft <= 0;
  String get _otpInput => _ctrl.map((c) => c.text).join();

  // ─── Actions ──────────────────────────────────────────────────────────────
  Future<void> _verify() async {
    if (_otpInput.length < 6) {
      _showSnack('Masukkan 6 digit kode OTP', isError: true);
      return;
    }
    setState(() => _isVerifying = true);
    final error = await _authController.verifyLoginOtp(_otpInput);
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (error == null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const HomePage(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      _showSnack(error, isError: true);
      for (final c in _ctrl) { c.clear(); }
      _focus[0].requestFocus();
    }
  }

  Future<void> _resend() async {
    if (!_isExpired || _isResending) return;
    setState(() => _isResending = true);
    final error = await _authController.sendLoginOtp();
    if (!mounted) return;
    setState(() => _isResending = false);

    if (error == null) {
      _startTimer();
      _showSnack('Kode baru sudah dikirim ke emailmu', isError: false);
    } else {
      _showSnack(error, isError: true);
    }
  }

  Future<void> _cancelAndLogout() async {
    // Logout Firebase — StreamBuilder di main.dart otomatis kembali ke AuthScreen
    await _authController.logout();
    // JANGAN Navigator.pop() — OtpScreen dibuka via pushReplacement sehingga
    // tidak ada route di bawahnya. Pop akan menyebabkan black screen.
    // StreamBuilder di main.dart akan rebuild ke AuthScreen setelah signOut.
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.red.shade400 : const Color(0xFF1BAB8A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── OTP Box Logic ────────────────────────────────────────────────────────
  void _onChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focus[index + 1].requestFocus();
      } else {
        _focus[index].unfocus();
        // Auto-verify saat semua terisi
        if (_otpInput.length == 6) _verify();
      }
    }
  }

  void _onBackspace(int index) {
    if (_ctrl[index].text.isEmpty && index > 0) {
      _focus[index - 1].requestFocus();
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _cancelAndLogout();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildHeader(sw, sh),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, sh * 0.035, 24, 24),
                  child: Column(
                    children: [
                      _buildEmailCard(),
                      SizedBox(height: sh * 0.035),
                      _buildOtpBoxes(sw),
                      SizedBox(height: 14),
                      _buildTimer(),
                      SizedBox(height: sh * 0.04),
                      _buildVerifyBtn(),
                      SizedBox(height: 12),
                      _buildResendBtn(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(double sw, double sh) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: sh * 0.06,
        left: 20,
        right: 20,
        bottom: sh * 0.03,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1BAB8A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _cancelAndLogout,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          SizedBox(height: sh * 0.018),
          Text(
            'Verifikasi\nIdentitasmu 🔐',
            style: TextStyle(
              color: Colors.white,
              fontSize: sw * 0.056,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          SizedBox(height: sh * 0.006),
          Text(
            'Masukkan kode 6 digit yang dikirim ke emailmu',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: sw * 0.031,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Email Card ───────────────────────────────────────────────────────────
  Widget _buildEmailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1BAB8A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.email_outlined,
              color: Color(0xFF1BAB8A),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kode dikirim ke',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF222222),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── OTP Boxes ────────────────────────────────────────────────────────────
  Widget _buildOtpBoxes(double sw) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) => _buildBox(i, sw)),
    );
  }

  Widget _buildBox(int index, double sw) {
    final size = sw * 0.13;
    return SizedBox(
      width: size,
      height: size * 1.1,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            _onBackspace(index);
          }
        },
        child: TextField(
          controller: _ctrl[index],
          focusNode: _focus[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: sw * 0.055,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF222222),
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE5E5E5), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE5E5E5), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF1BAB8A), width: 2),
            ),
          ),
          onChanged: (val) => _onChanged(index, val),
        ),
      ),
    );
  }

  // ─── Timer ────────────────────────────────────────────────────────────────
  Widget _buildTimer() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Row(
        key: ValueKey(_isExpired),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
            size: 14,
            color: _isExpired ? Colors.red.shade400 : const Color(0xFF999999),
          ),
          const SizedBox(width: 5),
          Text(
            _isExpired
                ? 'Kode kadaluarsa — minta kode baru'
                : 'Kode berlaku $_timerText',
            style: TextStyle(
              fontSize: 12,
              color:
                  _isExpired ? Colors.red.shade400 : const Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Verify Button ────────────────────────────────────────────────────────
  Widget _buildVerifyBtn() {
    final disabled = _isVerifying || _isExpired;
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: disabled ? null : _verify,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1BAB8A),
          disabledBackgroundColor: const Color(0xFF1BAB8A).withValues(alpha: 0.4),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isVerifying
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Verifikasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.shield_outlined, color: Colors.white, size: 16),
                ],
              ),
      ),
    );
  }

  // ─── Resend Button ────────────────────────────────────────────────────────
  Widget _buildResendBtn() {
    final canResend = _isExpired && !_isResending;
    return GestureDetector(
      onTap: canResend ? _resend : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          border: Border.all(
            color: canResend
                ? const Color(0xFF1BAB8A)
                : const Color(0xFFE0E0E0),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
        ),
        child: Center(
          child: _isResending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF1BAB8A),
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  _isExpired
                      ? 'Kirim Ulang Kode'
                      : 'Kirim ulang (tersedia saat kode expired)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isExpired
                        ? const Color(0xFF1BAB8A)
                        : const Color(0xFFBBBBBB),
                  ),
                ),
        ),
      ),
    );
  }
}
