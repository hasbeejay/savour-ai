import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); // Added for name

  bool _isLoading = false;
  bool _isSignUp = false;

  Future<void> _signInWithEmail() async {
    // Validate fields based on mode
    if (_isSignUp) {
      // Signup validation - check all fields
      if (_emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }
    } else {
      // Login validation - only email and password
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        // 1. Create user in Firebase Auth
        UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 2. Save user name to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': DateTime.now(),
        });

        // Optional: Update display name in Firebase Auth
        await userCredential.user!.updateDisplayName(_nameController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Login flow remains the same
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Authentication failed'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC6713F),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Image.asset(
                  "assets/transparentApplogo.png",
                  height: 180,
                ),
                const SizedBox(height: 20),

                /// -------- GLASS CARD --------
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isSignUp
                                ? 'Create Account!'
                                : 'Welcome to Savour!',
                            style: GoogleFonts.ptSans(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2E2E),
                            ),
                          ),
                          const SizedBox(height: 25),

                          // Show name field only during signup
                          if (_isSignUp) ...[
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                            ),
                            const SizedBox(height: 15),
                          ],

                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                          ),
                          const SizedBox(height: 15),

                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            isPassword: true,
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signInWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF753C03),
                                padding:
                                const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                                  : Text(
                                _isSignUp ? 'Sign Up' : 'Sign In',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                // Clear name field when switching to login
                                if (!_isSignUp) {
                                  _nameController.clear();
                                }
                              });
                            },
                            child: Text(
                              _isSignUp
                                  ? 'Already have an account? Sign In'
                                  : 'Don\'t have an account? Sign Up',
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),
                          const Divider(color: Colors.white70),
                          const SizedBox(height: 15),

                          /// ---- MOCK SOCIAL BUTTONS ----
                          _socialButton(
                            icon: 'assets/google.png',
                            text: 'Continue with Google',
                          ),
                          const SizedBox(height: 10),
                          _socialButton(
                            icon: 'assets/apple.png',
                            text: 'Continue with Apple',
                          ),
                          const SizedBox(height: 10),
                          _socialButton(
                            icon: 'assets/facebook.png',
                            text: 'Continue with Facebook',
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

  /// --------- CUSTOM TEXT FIELD ----------
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        // Add clear button for better UX
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear, size: 20),
          onPressed: () => controller.clear(),
        )
            : null,
      ),
    );
  }

  /// --------- MOCK SOCIAL BUTTON ----------
  Widget _socialButton({
    required String icon,
    required String text,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('coming soon'),
            ),
          );
        },
        icon: Image.asset(icon, height: 22),
        label: Text(
          text,
          style: const TextStyle(color: Colors.black87),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.white.withOpacity(0.65),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controllers
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}