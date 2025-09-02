import 'package:flutter/material.dart';
import '../main.dart';
import '../services/database_service.dart';
import 'package:firebase_core/firebase_core.dart';

class LoginPage
    extends
        StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<
    LoginPage
  >
  createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends
        State<
          LoginPage
        > {
  final _formKey =
      GlobalKey<
        FormState
      >();
  final _usernameController =
      TextEditingController();
  final _passwordController =
      TextEditingController();
  bool _isLoading =
      false;
  bool _obscurePassword =
      true;
  bool _isFirebaseInitialized =
      false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<
    void
  >
  _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      if (mounted) {
        setState(
          () {
            _isFirebaseInitialized =
                true;
          },
        );
      }
    } catch (
      e
    ) {
      print(
        'Error initializing Firebase: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Error initializing app: $e',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    }
  }

  Future<
    void
  >
  _login() async {
    print(
      'Login: Starting login process',
    );
    if (!_isFirebaseInitialized) {
      print(
        'Login: Firebase not initialized',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Please wait while the app initializes',
          ),
          backgroundColor:
              Colors.orange,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      print(
        'Login: Form validated, username: ${_usernameController.text}',
      );
      setState(
        () {
          _isLoading =
              true;
        },
      );

      try {
        print(
          'Login: Creating DatabaseService instance',
        );
        final databaseService =
            DatabaseService();

        print(
          'Login: Attempting to get user from database',
        );
        final user = await databaseService.getUser(
          _usernameController.text,
        );
        print(
          'Login: Database response received',
        );

        if (user ==
            null) {
          print(
            'Login: User not found in database',
          );
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              const SnackBar(
                content: Text(
                  'User not found',
                ),
                backgroundColor:
                    Colors.red,
              ),
            );
          }
          return;
        }

        print(
          'Login: User found, verifying password',
        );
        if (user.password !=
            _passwordController.text) {
          print(
            'Login: Invalid password',
          );
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              const SnackBar(
                content: Text(
                  'Invalid password',
                ),
                backgroundColor:
                    Colors.red,
              ),
            );
          }
          return;
        }

        print(
          'Login: Password verified, setting current user',
        );
        // Set the current user
        currentUser =
            user;
        print(
          'Login: Current user set successfully',
        );

        if (mounted) {
          print(
            'Login: Navigating to home page',
          );
          Navigator.pushReplacementNamed(
            context,
            '/home',
          );
        }
      } catch (
        e,
        stackTrace
      ) {
        print(
          'Login error: $e',
        );
        print(
          'Stack trace: $stackTrace',
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(
              content: Text(
                'Error logging in: $e',
              ),
              backgroundColor:
                  Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(
            () {
              _isLoading =
                  false;
            },
          );
        }
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(
              24.0,
            ),
            child: Form(
              key:
                  _formKey,
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(
                    height:
                        60,
                  ),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize:
                          32,
                      fontWeight:
                          FontWeight.bold,
                    ),
                    textAlign:
                        TextAlign.center,
                  ),
                  const SizedBox(
                    height:
                        48,
                  ),
                  TextFormField(
                    controller:
                        _usernameController,
                    decoration: InputDecoration(
                      labelText:
                          'Username or Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                      ),
                    ),
                    validator: (
                      value,
                    ) {
                      if (value ==
                              null ||
                          value.isEmpty) {
                        return 'Please enter your username or email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height:
                        16,
                  ),
                  TextFormField(
                    controller:
                        _passwordController,
                    decoration: InputDecoration(
                      labelText:
                          'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(
                            () {
                              _obscurePassword =
                                  !_obscurePassword;
                            },
                          );
                        },
                      ),
                    ),
                    obscureText:
                        _obscurePassword,
                    validator: (
                      value,
                    ) {
                      if (value ==
                              null ||
                          value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height:
                        24,
                  ),
                  ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical:
                            16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height:
                                  20,
                              width:
                                  20,
                              child: CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                valueColor: AlwaysStoppedAnimation<
                                  Color
                                >(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                  ),
                  const SizedBox(
                    height:
                        16,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/signup',
                      );
                    },
                    child: const Text(
                      'Don\'t have an account? Sign up',
                      style: TextStyle(
                        fontSize:
                            16,
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
