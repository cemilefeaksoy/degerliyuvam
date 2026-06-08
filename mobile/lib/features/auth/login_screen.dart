import 'package:flutter/material.dart';

import '../../core/state/app_scope.dart';
import '../../shared/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassPanel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hesabına giriş yap',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                          'Favori ilanlar, mesajlar ve teklif akışı için devam et.'),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'E-posta gerekli'
                                : null,
                        decoration: const InputDecoration(labelText: 'E-posta'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) =>
                            (value == null || value.length < 6)
                                ? 'Şifre gerekli'
                                : null,
                        decoration: const InputDecoration(labelText: 'Şifre'),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  setState(() => _loading = true);
                                  try {
                                    final rememberMe =
                                        await _askRememberMe(context);
                                    if (rememberMe == null) return;
                                    await controller.login(
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                      rememberMe: rememberMe,
                                    );
                                    if (mounted) Navigator.of(context).pop();
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _loading = false);
                                    }
                                  }
                                },
                          child: Text(
                              _loading ? 'Giriş yapılıyor...' : 'Giriş Yap'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text('Hesabın yok mu? Kayıt ol'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen()),
                        ),
                        child: const Text('Şifremi unuttum'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _askRememberMe(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Beni Hatırla'),
        content: const Text(
            'Giriş yaptığınız oturumun hatırlanmasını ister misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Sadece Bu Oturum'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hatırla'),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeRequested = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = AppScope.of(context).api;
    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassPanel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Şifreyi yenile',
                        subtitle:
                            'E-posta adresinize ait sıfırlama koduyla yeni şifre belirleyin.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        enabled: !_codeRequested,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'E-posta'),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          return text.contains('@')
                              ? null
                              : 'Geçerli bir e-posta girin';
                        },
                      ),
                      if (_codeRequested) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _code,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: '6 haneli sıfırlama kodu'),
                          validator: (value) => (value?.trim().length ?? 0) == 6
                              ? null
                              : 'Kod 6 haneli olmalı',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration:
                              const InputDecoration(labelText: 'Yeni şifre'),
                          validator: (value) => (value?.length ?? 0) >= 6
                              ? null
                              : 'En az 6 karakter girin',
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  setState(() => _loading = true);
                                  try {
                                    if (!_codeRequested) {
                                      final code = await api
                                          .forgotPassword(_email.text.trim());
                                      if (!mounted) return;
                                      setState(() {
                                        _codeRequested = true;
                                        if (code != null) _code.text = code;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Sıfırlama kodu oluşturuldu.')),
                                      );
                                    } else {
                                      await api.resetPassword(
                                        email: _email.text.trim(),
                                        resetCode: _code.text.trim(),
                                        newPassword: _password.text,
                                      );
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Şifreniz güncellendi.')),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text('$e')),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _loading = false);
                                    }
                                  }
                                },
                          child: Text(
                            _loading
                                ? 'İşleniyor...'
                                : (_codeRequested
                                    ? 'Şifreyi Güncelle'
                                    : 'Kod Oluştur'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassPanel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yeni hesap oluştur',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                          'İlanlara bakmak, mesaj göndermek ve teklif vermek için kayıt ol.'),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _nameController,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Ad soyad gerekli'
                                : null,
                        decoration:
                            const InputDecoration(labelText: 'Ad Soyad'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'E-posta gerekli'
                                : null,
                        decoration: const InputDecoration(labelText: 'E-posta'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Telefon gerekli'
                                : null,
                        decoration: const InputDecoration(labelText: 'Telefon'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) =>
                            (value == null || value.length < 6)
                                ? 'En az 6 karakter'
                                : null,
                        decoration: const InputDecoration(labelText: 'Şifre'),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  setState(() => _loading = true);
                                  try {
                                    await controller.register(
                                      fullName: _nameController.text.trim(),
                                      email: _emailController.text.trim(),
                                      phoneNumber: _phoneController.text.trim(),
                                      password: _passwordController.text,
                                    );
                                    if (mounted) Navigator.of(context).pop();
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _loading = false);
                                    }
                                  }
                                },
                          child: Text(
                              _loading ? 'Kayıt oluşturuluyor...' : 'Kayıt Ol'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
