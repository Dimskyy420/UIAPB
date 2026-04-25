import 'package:flutter/material.dart';
import '../controller/auth_controller.dart';
import 'home.dart'; // sesuaikan path

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // ─── State ────────────────────────────────────────────────────────────────
  bool _isLogin = true;
  bool _isLoading = false;
  bool _loginObscure = true;
  bool _regObscure = true;
  bool _regConfirmObscure = true;

  // ─── Controllers ──────────────────────────────────────────────────────────
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regUniversityCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regNameCtrl.dispose();
    _regUniversityCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  void _switchTab(bool toLogin) {
    if (_isLogin == toLogin) return;
    _animCtrl.reverse().then((_) {
      setState(() => _isLogin = toLogin);
      _animCtrl.forward();
    });
  }

  Future<void> _handleGoogle() async {
    setState(() => _isLoading = true);
    final error = await _authController.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      _goHome();
    } else if (error != 'Login dibatalkan') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          _buildHeader(sw, sh),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, sh * 0.028, 18, 20),
              child: Column(
                children: [
                  _buildTabToggle(),
                  SizedBox(height: sh * 0.024),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child:
                        _isLogin ? _buildLoginForm() : _buildRegisterForm(),
                  ),
                ],
              ),
            ),
          ),
        ],
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
          // Logo
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text('🤝',
                      style: TextStyle(fontSize: sw * 0.045)),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'TASURU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: sw * 0.042,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: sh * 0.018),
          // Dynamic title
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Column(
              key: ValueKey(_isLogin),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLogin
                      ? 'Selamat datang\nkembali!'
                      : 'Daftar & mulai\nbantuan kamu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: sw * 0.056,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: sh * 0.006),
                Text(
                  _isLogin
                      ? 'Masuk ke akun TASURU kamu'
                      : 'Bergabung dengan komunitas mahasiswa TASURU',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: sw * 0.031,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab Toggle ───────────────────────────────────────────────────────────
  Widget _buildTabToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAED),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tabItem('Masuk', isActive: _isLogin,
              onTap: () => _switchTab(true)),
          _tabItem('Daftar', isActive: !_isLogin,
              onTap: () => _switchTab(false)),
        ],
      ),
    );
  }

  Widget _tabItem(String label,
      {required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? const Color(0xFF1BAB8A)
                  : const Color(0xFF999999),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Login Form ───────────────────────────────────────────────────────────
  Widget _buildLoginForm() {
    return Column(
      children: [
        _field(
          controller: _loginEmailCtrl,
          hint: 'Email kampus',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 11),
        _passwordField(
          controller: _loginPasswordCtrl,
          hint: 'Kata sandi',
          obscure: _loginObscure,
          onToggle: () => setState(() => _loginObscure = !_loginObscure),
        ),
        const SizedBox(height: 7),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: const Text(
              'Lupa kata sandi?',
              style: TextStyle(
                color: Color(0xFF1BAB8A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _submitButton(label: 'Masuk'),
        const SizedBox(height: 16),
        _divider(),
        const SizedBox(height: 13),
        _googleButton(),
      ],
    );
  }

  // ─── Register Form ────────────────────────────────────────────────────────
  Widget _buildRegisterForm() {
    return Column(
      children: [
        _field(
          controller: _regNameCtrl,
          hint: 'Nama lengkap',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 11),
        _field(
          controller: _regUniversityCtrl,
          hint: 'Universitas',
          icon: Icons.menu_book_outlined,
        ),
        const SizedBox(height: 11),
        _field(
          controller: _regEmailCtrl,
          hint: 'Email kampus',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 11),
        _passwordField(
          controller: _regPasswordCtrl,
          hint: 'Kata sandi',
          obscure: _regObscure,
          onToggle: () => setState(() => _regObscure = !_regObscure),
        ),
        const SizedBox(height: 11),
        _passwordField(
          controller: _regConfirmCtrl,
          hint: 'Konfirmasi kata sandi',
          obscure: _regConfirmObscure,
          onToggle: () =>
              setState(() => _regConfirmObscure = !_regConfirmObscure),
        ),
        const SizedBox(height: 18),
        _submitButton(label: 'Daftar Sekarang'),
        const SizedBox(height: 16),
        _divider(),
        const SizedBox(height: 13),
        _googleButton(),
      ],
    );
  }

  // ─── Reusable Widgets ─────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13.5, color: Color(0xFF222222)),
      decoration: _inputDeco(hint: hint, prefixIcon: icon),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 13.5, color: Color(0xFF222222)),
      decoration:
          _inputDeco(hint: hint, prefixIcon: Icons.lock_outline_rounded)
              .copyWith(
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFFAAAAAA),
            size: 18,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
      prefixIcon:
          Icon(prefixIcon, color: const Color(0xFFBBBBBB), size: 18),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFFE5E5E5), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFFE5E5E5), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF1BAB8A), width: 1.5),
      ),
    );
  }

  Widget _submitButton({required String label}) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _goHome,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1BAB8A),
          disabledBackgroundColor:
              const Color(0xFF1BAB8A).withOpacity(0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16),
                ],
              ),
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        Expanded(
            child:
                Divider(color: Colors.grey.shade300, thickness: 0.8)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'atau lanjut dengan',
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ),
        Expanded(
            child:
                Divider(color: Colors.grey.shade300, thickness: 0.8)),
      ],
    );
  }

  // ─── Google Button ────────────────────────────────────────────────────────
  Widget _googleButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogle,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF1BAB8A),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Lanjut dengan Google',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}