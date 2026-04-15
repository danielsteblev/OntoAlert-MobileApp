import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  final Future<void> Function(String username, String password) onLogin;
  final Future<void> Function(String username, String email, String password, String fullName) onRegister;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF25A4FF), Color(0xFF1C5BFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    Icon(Icons.school_rounded, size: 72, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Fast-learning',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Юридический помощник для быстрого освоения главы 20 КоАП РФ',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TabBar(
                controller: _controller,
                tabs: const [Tab(text: 'Вход'), Tab(text: 'Регистрация')],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _controller,
                  children: [
                    _LoginForm(onSubmit: widget.onLogin),
                    _RegisterForm(onSubmit: widget.onRegister),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.onSubmit});

  final Future<void> Function(String username, String password) onSubmit;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(_usernameController.text.trim(), _passwordController.text.trim());
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(labelText: 'Введите логин'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Введите пароль'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: Text(_isLoading ? 'Входим...' : 'Войти'),
        ),
      ],
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({required this.onSubmit});

  final Future<void> Function(String username, String email, String password, String fullName) onSubmit;

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _fullNameController.text.trim(),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _fullNameController,
          decoration: const InputDecoration(labelText: 'ФИО'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(labelText: 'Логин'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Почта'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Пароль'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: Text(_isLoading ? 'Создаём аккаунт...' : 'Регистрация'),
        ),
      ],
    );
  }
}
