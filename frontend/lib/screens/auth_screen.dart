import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              children: [
                Text(
                  'RideLog',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Melde dich mit deiner Email an'
                      : 'Erstelle deinen Account',
                  style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_isLogin) ...[
                            const Text('Name'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (_isLogin) return null;
                                if (value == null || value.trim().isEmpty) {
                                  return 'Bitte Namen eingeben';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          const Text('Email'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty || !text.contains('@')) {
                                return 'Bitte gültige Email eingeben';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text('Passwort'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              final text = value ?? '';
                              if (text.length < 8) {
                                return 'Mindestens 8 Zeichen';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: userProvider.isLoading ? null : _submit,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(_isLogin ? 'Einloggen' : 'Registrieren'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: userProvider.isLoading
                                  ? null
                                  : () {
                                      setState(() => _isLogin = !_isLogin);
                                    },
                              child: Text(
                                _isLogin
                                    ? 'Noch kein Konto? Registrieren'
                                    : 'Bereits ein Konto? Einloggen',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await userProvider.login(email: email, password: password);
      } else {
        await userProvider.register(
          email: email,
          password: password,
          name: _nameController.text.trim(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}
