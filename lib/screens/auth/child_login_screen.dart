import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';

class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final _usernameController = TextEditingController();
  String _pin = '';
  bool _loading = false;

  Future<void> _submit() async {
    if (_usernameController.text.isEmpty || _pin.length != 4) return;

    setState(() => _loading = true);
    try {
      final child = await AuthService.signInChild(
        username: _usernameController.text.trim(),
        pin: _pin,
      );
      if (child != null && mounted) {
        await SessionService.saveChildSession(child);
        Navigator.pushReplacementNamed(context, '/child-home', arguments: child);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario ou PIN incorreto')),
        );
      }
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

  void _onPinDigit(String digit) {
    if (_pin.length < 4) {
      setState(() => _pin += digit);
      if (_pin.length == 4) _submit();
    }
  }

  void _onPinDelete() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acesso Filho(a)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🧒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Seu usuario',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Digite seu PIN',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: i < _pin.length ? AppColors.childGreen : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: i < _pin.length ? AppColors.childGreen : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: i < _pin.length
                      ? const Icon(Icons.circle, size: 16, color: Colors.white)
                      : null,
                ),
              )),
            ),
            const SizedBox(height: 32),
            if (_loading)
              const CircularProgressIndicator()
            else
              _buildPinPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildPinPad() {
    final buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: buttons.map((row) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: row.map((label) {
          if (label.isEmpty) return const SizedBox(width: 72, height: 72);
          return Padding(
            padding: const EdgeInsets.all(6),
            child: Material(
              color: label == '⌫' ? AppColors.border : AppColors.childGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: label == '⌫' ? _onPinDelete : () => _onPinDigit(label),
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: label == '⌫' ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      )).toList(),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
