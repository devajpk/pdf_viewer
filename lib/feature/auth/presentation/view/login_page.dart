import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf_viewer/feature/auth/data/repo/repo_imp.dart';
import 'package:pdf_viewer/feature/auth/domain/repo/repo.dart';
import 'package:pdf_viewer/feature/auth/presentation/view/signg_up.dart';
import 'package:pdf_viewer/feature/auth/presentation/view_model/auth_bloc.dart';
import 'package:pdf_viewer/feature/auth/presentation/view_model/auth_event.dart';
import 'package:pdf_viewer/feature/auth/presentation/view_model/auth_state.dart';
import 'package:pdf_viewer/feature/pdf/presentation/view/pdf_screen.dart';

class Login extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider(
      create: (context) => AuthBloc(AuthRepositoryImpl(FirebaseAuth.instance)),
      child: Scaffold(
        body: BlocListener<AuthBloc, AuthState>(
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
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade700,
                  Colors.purple.shade600,
                  Colors.deepPurple.shade800,
                ],
              ),
            ),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Header Section
                  Container(
                    height: size.height * 0.35,
                    child: Stack(
                      children: [
                        Positioned(
                          top: size.height * 0.1,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              // Animated Logo/Icon
                              AnimatedContainer(
                                duration: Duration(seconds: 2),
                                curve: Curves.fastOutSlowIn,
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.description,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'PDF Viewer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Access your documents securely',
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

                  // Login Form Section
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: size.height * 0.65,
                    ),
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
                              'Welcome Back!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please sign in to continue',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 40),

                            // Email Field
                            _buildTextField(
                              controller: emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 25),

                            // Password Field
                            _buildPasswordField(),
                            SizedBox(height: 30),

                            // Login Button
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                return _buildAuthButton(state, context);
                              },
                            ),
                            SizedBox(height: 25),

                            // Divider
                            _buildDivider(),
                            SizedBox(height: 25),

                            // Sign Up Section
                            _buildSignUpSection(context),
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
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }

  Widget _buildPasswordField() {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isObscure = true;
        return TextFormField(
          controller: passwordController,
          obscureText: isObscure,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          style: TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.blue.shade700),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade500,
              ),
              onPressed: () {
                setState(() {
                  isObscure = !isObscure;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          ),
        );
      },
    );
  }

  Widget _buildAuthButton(AuthState state, BuildContext context) {
    if (state is AuthLoading) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.blue.shade700.withOpacity(0.7),
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
            colors: [Colors.blue.shade700, Colors.purple.shade600],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              context.read<AuthBloc>().add(LoginEvent(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  ));
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
              Icon(Icons.login, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'SIGN IN',
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
        Expanded(
          child: Divider(color: Colors.grey.shade300),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'New to PDF Viewer?',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.grey.shade300),
        ),
      ],
    );
  }

  Widget _buildSignUpSection(BuildContext context) {
    return Column(
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue.shade700, width: 2),
          ),
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => SignupScreen()), // Replace with your actual home screen
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
                Icon(Icons.person_add, color: Colors.blue.shade700),
                SizedBox(width: 10),
                Text(
                  'CREATE ACCOUNT',
                  style: TextStyle(
                    color: Colors.blue.shade700,
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