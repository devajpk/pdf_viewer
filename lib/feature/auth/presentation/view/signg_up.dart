import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf_viewer/feature/auth/data/repo/repo_imp.dart';
import 'package:pdf_viewer/feature/auth/presentation/view/login_page.dart';
import 'package:pdf_viewer/feature/pdf/presentation/view/pdf_screen.dart';
import '../view_model/auth_bloc.dart';
import '../view_model/auth_event.dart';
import '../view_model/auth_state.dart';

class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Move obscure text state to main widget state
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsChecked = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider(
      create: (context) => AuthBloc(AuthRepositoryImpl(FirebaseAuth.instance)),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is AuthSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => PdfListPage()),
            );
          }
        },
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade700,
                  Colors.blue.shade600,
                  Colors.lightBlue.shade400,
                ],
              ),
            ),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Header Section
                  Container(
                    height: size.height * 0.3,
                    child: Stack(
                      children: [
                        Positioned(
                          top: size.height * 0.08,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              // Animated Logo/Icon
                              AnimatedContainer(
                                duration: Duration(seconds: 2),
                                curve: Curves.fastOutSlowIn,
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_add_alt_1,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Join us today!',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Signup Form Section
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: size.height * 0.7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20),

                            // Welcome Text
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade900,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create your account in seconds',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 40),

                            // Full Name Field
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your full name';
                                }
                                if (value.length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),

                            // Email Field
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),

                            // Password Field
                            _buildPasswordField(
                              controller: _passwordController,
                              label: 'Password',
                              obscureText: _obscurePassword,
                              onToggle: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            SizedBox(height: 20),

                            // Confirm Password Field
                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              obscureText: _obscureConfirmPassword,
                              onToggle: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            SizedBox(height: 30),

                            // Terms and Conditions
                            _buildTermsCheckbox(),
                            SizedBox(height: 25),

                            // Signup Button
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                return _buildSignupButton(state, context);
                              },
                            ),
                            SizedBox(height: 25),

                            // Divider
                            _buildDivider(),
                            SizedBox(height: 25),

                            // Login Redirect
                            _buildLoginRedirect(context),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.purple.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.purple.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (label == 'Confirm Password' && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.purple.shade700),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade500,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.purple.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _termsChecked,
          onChanged: (value) {
            setState(() {
              _termsChecked = value!;
            });
          },
          activeColor: Colors.purple.shade700,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _termsChecked = !_termsChecked;
              });
            },
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                children: [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton(AuthState state, BuildContext context) {
    if (state is AuthLoading) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.purple.shade700.withOpacity(0.7),
        ),
        child: Center(
          child: SizedBox(
            height: 25,
            width: 25,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return Material(
      borderRadius: BorderRadius.circular(15),
      elevation: 5,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.purple.shade700, Colors.blue.shade600],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              if (!_termsChecked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please accept the Terms & Conditions'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              context.read<AuthBloc>().add(
                SignupEvent(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                ),
              );
            }
          },
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'CREATE ACCOUNT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'Already have an account?',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildLoginRedirect(BuildContext context) {
    return Column(
      children: [
        Text(
          "Already have an account?",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.purple.shade700, width: 2),
          ),
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => Login()),
              );
            },
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, color: Colors.purple.shade700),
                SizedBox(width: 10),
                Text(
                  'SIGN IN INSTEAD',
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
