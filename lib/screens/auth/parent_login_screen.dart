import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';

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
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        await AuthService.signUpParent(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          familyName: _familyController.text.trim(),
        );
      } else {
        await AuthService.signInParent(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/parent-dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp ? 'Ja tenho conta' : 'Criar nova conta'),
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
