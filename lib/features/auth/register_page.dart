import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_app_mobile/core/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:sales_app_mobile/providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final dio = ref.read(dioProvider);
    final authNotifier = ref.read(authProvider.notifier);

    try {
      // 1. Register User
      final registerRes = await dio.post('/auth/local/register', data: {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });

      final userJson = registerRes.data['user'];
      final jwt = registerRes.data['jwt'];
      final user = User.fromJson(userJson);

      // 2. Auto-Login in Store
      await authNotifier.login(user, jwt, isApproved: false);

      // 3. Create Sales Profile
      try {
        await dio.post('/sales-profiles', 
          data: {
            'data': {
              'sales_uid': 'SALES-${DateTime.now().millisecondsSinceEpoch}',
              'email': user.email,
              'surename': user.username.toUpperCase(),
              'approved': false,
              'blocked': false,
            }
          },
          options: Options(
            headers: {'Authorization': 'Bearer $jwt'},
          ),
        );
      } catch (e) {
        print("Failed to create sales profile: $e");
        // Proceed anyway, strict parity with web app behavior
      }

      if (mounted) {
        context.go('/profile');
      }

    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['error']?['message'] ?? 'Registration failed';
      });
    } catch (e) {
      print(e);
      setState(() {
        _errorMessage = "An unexpected error occurred.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                     BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Border
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Header
                            Container(
                              width: 64,
                              height: 64,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_add, size: 32), 
                            ),
                            Text(
                              "Join Sales App",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Create a new account for Sales Access.",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 32),

                            // Inputs
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: "Username",
                                hintText: "johndoe",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 3) {
                                  return "Username must be at least 3 characters";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: "Email",
                                hintText: "sales@dealer.com",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) return "Invalid email address";
                                if (!value.contains('@')) return "Invalid email address";
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: "Password",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return "Password must be at least 6 characters";
                                }
                                return null;
                              },
                            ),
                             const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: const InputDecoration(
                                labelText: "Confirm Password",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return "Passwords don't match";
                                }
                                return null;
                              },
                            ),
                            
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),

                            const SizedBox(height: 24),
                            
                            // Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _onSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: Text(_isLoading ? 'Creating Account...' : 'Register'),
                              ),
                            ),

                            const SizedBox(height: 16),
                            
                            // Login Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Already have an account? ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                GestureDetector(
                                  onTap: () => context.go('/auth/login'),
                                  child: Text(
                                    "Login",
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
