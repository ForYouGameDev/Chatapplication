import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController(text: '+91');
  final _otp = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      final g = GoogleSignIn(serverClientId: AppConfig.googleWebClientId);
      final account = await g.signIn();
      if (account == null) return; // user ne cancel kiya
      final auth = await account.authentication;
      if (auth.idToken == null) throw 'Google ID token nahi mila';
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: auth.idToken!,
        accessToken: auth.accessToken,
      );
    } catch (e) {
      if (mounted) _msg('Google login fail: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendOtp() async {
    final p = _phone.text.trim();
    if (!RegExp(r'^\+\d{8,15}$').hasMatch(p)) {
      _msg('Number country code ke saath daalo, jaise +919876543210');
      return;
    }
    setState(() => _busy = true);
    try {
      await supabase.auth.signInWithOtp(phone: p);
      setState(() => _otpSent = true);
    } on AuthException catch (e) {
      _msg(e.message);
    } catch (e) {
      _msg('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _busy = true);
    try {
      await supabase.auth.verifyOTP(
        phone: _phone.text.trim(),
        token: _otp.text.trim(),
        type: OtpType.sms,
      );
    } on AuthException catch (e) {
      _msg(e.message);
    } catch (e) {
      _msg('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.chat, size: 72, color: Color(0xFF25D366)),
                const SizedBox(height: 12),
                const Text('Chat Clone',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _busy ? null : _google,
                  icon: const Icon(Icons.g_mobiledata, size: 32),
                  label: const Text('Google se login'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('ya')),
                    Expanded(child: Divider()),
                  ]),
                ),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  enabled: !_otpSent,
                  decoration: const InputDecoration(
                      labelText: 'Phone number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone)),
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _otp,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'OTP',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sms)),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : (_otpSent ? _verifyOtp : _sendOtp),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_otpSent ? 'OTP verify karo' : 'OTP bhejo'),
                ),
                if (_otpSent)
                  TextButton(
                      onPressed: () => setState(() => _otpSent = false),
                      child: const Text('Number badlo')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
