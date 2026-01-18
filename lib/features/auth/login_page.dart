import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_app_mobile/core/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:sales_app_mobile/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      // 1. Authenticate
      final response = await dio.post('/auth/local', data: {
        'identifier': _emailController.text.trim(),
        'password': _passwordController.text,
      });

      final userJson = response.data['user'];
      final jwt = response.data['jwt'];
      final user = User.fromJson(userJson);

      // 2. Check Sales Profile
      bool isApproved = false;
      try {
        final profileRes = await dio.get('/sales-profiles', queryParameters: {
          'filters[email][\$eq]': user.email,
        }, options: Options(
          headers: {'Authorization': 'Bearer $jwt'},
        ));

        final data = profileRes.data['data'] as List;
        if (data.isNotEmpty) {
          final profileData = data[0];
          final attributes = profileData['attributes'];
          final profileId = profileData['id'];
          
          // Flatten attributes if needed (Strapi 4 structure)
          final profile = attributes != null ? {...attributes, 'id': profileId} : profileData;

          if (profile['blocked'] == true) {
            setState(() {
              _isLoading = false;
              _errorMessage = "Access Denied: You are blocked by admin.";
            });
            return;
          }

          final approvedVal = profile['approved'];
          isApproved = approvedVal == true || approvedVal == 'true';
        }
      } catch (e) {
        print("Profile check failed: $e");
        // Continue with isApproved = false
      }

      // 3. Login & Redirect
      await authNotifier.login(user, jwt, isApproved: isApproved);
      
      if (mounted) {
        if (isApproved) {
          context.go('/dashboard');
        } else {
          context.go('/profile');
        }
      }

    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['error']?['message'] ?? 'Invalid credentials';
      });
    } catch (e) {
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
    // Tailwind Default Primary typically Slate 900 or similar
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50], // bg-gray-50
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Card
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
                    // Top Border (border-t-4 border-t-primary)
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
                            // Logo Placeholder (mocking boxLogo)
                            Container(
                              width: 64,
                              height: 64,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.inventory_2, size: 32), 
                            ),
                            Text(
                              "Sales App",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Welcome back! Please login to continue.",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 32),

                            // Inputs
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
                                child: Text(_isLoading ? 'Logging in...' : 'Login'),
                              ),
                            ),

                            const SizedBox(height: 16),
                            
                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                GestureDetector(
                                  onTap: () => context.go('/auth/register'),
                                  child: Text(
                                    "Register",
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
              
              // Footer
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ).createShader(bounds),
                child: const Text(
                  "Karunia Apps @nababancloud.net 2025",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Trial Version 1.0.1",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
