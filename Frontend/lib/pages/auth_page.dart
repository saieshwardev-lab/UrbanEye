import 'package:flutter/material.dart';
import 'package:urban_eye/services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showRegister = false;

  void _onSignedIn() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstChild: AuthCard(
                title: 'Welcome back',
                subtitle: 'Sign in to track and report issues in your area.',
                child: LoginForm(onSignedIn: _onSignedIn, switchToRegister: () => setState(() => showRegister = true)),
              ),
              secondChild: AuthCard(
                title: 'Create account',
                subtitle: 'Join your local community — report and upvote issues.',
                child: RegisterForm(onSignedIn: _onSignedIn, switchToLogin: () => setState(() => showRegister = false)),
              ),
              crossFadeState: showRegister ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Center(
          child: Text(
            'By signing in you agree to the community guidelines',
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

/// A reusable card for auth pages (keeps layout consistent)
class AuthCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const AuthCard({Key? key, required this.title, required this.subtitle, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width > 700 ? 600.0 : width * 0.94;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cardWidth),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 26.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Logo / Leading
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('UE', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Text('UrbanEye', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: Colors.black87)),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------------
   LOGIN FORM
   ------------------------- */

class LoginForm extends StatefulWidget {
  final VoidCallback onSignedIn;
  final VoidCallback switchToRegister;
  const LoginForm({Key? key, required this.onSignedIn, required this.switchToRegister}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await AuthService.signIn(email: _email.text.trim(), password: _pass.text);
    setState(() => _loading = false);
    if (ok) {
      widget.onSignedIn();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid credentials (mock)')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!_emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                return null;
              }, prefixIcon: Icons.email_outlined),
              const SizedBox(height: 12),
              _buildTextField(controller: _pass, label: 'Password', obscureText: true, validator: (v) {
                if (v == null || v.length < 6) return '6+ chars';
                return null;
              }, prefixIcon: Icons.lock_outline),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Sign in', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: widget.switchToRegister, child: const Text('Don\'t have an account? Register')),
              ),
              const SizedBox(height: 6),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    AuthService.signInAsGuest();
                    widget.onSignedIn();
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Continue as guest'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
    );
  }
}

/* -------------------------
   REGISTER FORM
   ------------------------- */

class RegisterForm extends StatefulWidget {
  final VoidCallback onSignedIn;
  final VoidCallback switchToLogin;
  const RegisterForm({Key? key, required this.onSignedIn, required this.switchToLogin}) : super(key: key);

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await AuthService.register(name: _name.text.trim(), email: _email.text.trim(), password: _pass.text);
    setState(() => _loading = false);
    if (ok) {
      widget.onSignedIn();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed (mock)')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(controller: _name, label: 'Full name', validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required', prefixIcon: Icons.person_outline),
              const SizedBox(height: 10),
              _buildTextField(controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!_emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                return null;
              }, prefixIcon: Icons.email_outlined),
              const SizedBox(height: 10),
              _buildTextField(controller: _pass, label: 'Password', obscureText: true, validator: (v) => v != null && v.length >= 6 ? null : '6+ chars', prefixIcon: Icons.lock_outline),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Register', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: widget.switchToLogin, child: const Text('Already have an account? Sign in')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
    );
  }
}
