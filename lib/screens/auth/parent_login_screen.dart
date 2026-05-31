import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _isSignUp = false;
  final _nameController = TextEditingController();
  final _familyController = TextEditingController();

  Future<void> _submit() async {
    if (_loading) return;
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showError('Preencha email e senha');
      return;
    }
    if (_isSignUp && (_nameController.text.trim().isEmpty || _familyController.text.trim().isEmpty)) {
      _showError('Preencha todos os campos');
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        await AuthService.signUpParent(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          familyName: _familyController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conta criada com sucesso! Bem-vindo(a)!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
          final route = AdminService.isAdmin() ? '/admin' : '/parent-dashboard';
          Navigator.pushReplacementNamed(context, route);
        }
      } else {
        await AuthService.signInParent(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          final route = AdminService.isAdmin() ? '/admin' : '/parent-dashboard';
          Navigator.pushReplacementNamed(context, route);
        }
      }
    } catch (e) {
      if (mounted) _showError(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login social em breve! Use email e senha por enquanto.'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  String _friendlyError(String error) {
    if (error.contains('Invalid login credentials')) return 'Email ou senha incorretos';
    if (error.contains('User already registered')) return 'Este email ja esta cadastrado. Tente fazer login.';
    if (error.contains('over_email_send_rate_limit') || error.contains('429')) return 'Muitas tentativas. Aguarde 1 minuto e tente novamente.';
    if (error.contains('Email not confirmed')) return 'Confirme seu email antes de fazer login.';
    if (error.contains('Password should be at least')) return 'A senha deve ter pelo menos 6 caracteres.';
    return error.replaceAll('AuthApiException(message: ', '').replaceAll(')', '');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acesso Pai/Mae')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('👨‍👩‍👦', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (_isSignUp) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Seu nome', prefixIcon: Icon(Icons.person)),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _familyController,
                decoration: const InputDecoration(labelText: 'Nome da familia', prefixIcon: Icon(Icons.family_restroom)),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock)),
              obscureText: true,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.parentBlue, foregroundColor: Colors.white),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isSignUp ? 'Criar Conta' : 'Entrar'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loading ? null : () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp ? 'Ja tenho conta' : 'Criar nova conta'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('ou continue com', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loading ? null : _showComingSoon,
              icon: const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))),
              label: const Text('Continuar com Google'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loading ? null : _showComingSoon,
              icon: const Icon(Icons.apple, size: 24, color: AppColors.textPrimary),
              label: const Text('Continuar com Apple'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _familyController.dispose();
    super.dispose();
  }
}
