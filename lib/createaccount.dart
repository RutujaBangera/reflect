import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:convert';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  CreateAccountPageState createState() => CreateAccountPageState();
}

class CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Reference to the users collection in Firestore
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  @override
  void initState() {
    super.initState();
  }

  // ✅ Function to validate email format
  bool isEmailValid(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      return false;
    }
    List<String> allowedDomains = ['gmail.com', 'yahoo.com', 'outlook.com'];
    String domain = email.split('@').last;
    return allowedDomains.contains(domain);
  }

  // ✅ Function to validate strong password
  bool isPasswordStrong(String password) {
    final strongPasswordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]{8,}$');
    return strongPasswordRegex.hasMatch(password);
  }

  // ✅ Function to check if account already exists in Firestore
  Future<bool> accountExists(String email, String username) async {
    // Check for duplicate email
    QuerySnapshot emailQuery = await _usersCollection
        .where('email', isEqualTo: email.toLowerCase().trim())
        .get();

    // Check for duplicate username
    QuerySnapshot usernameQuery = await _usersCollection
        .where('username', isEqualTo: username.trim())
        .get();

    return emailQuery.docs.isNotEmpty || usernameQuery.docs.isNotEmpty;
  }

  // ✅ Create account logic with Firestore
  void _createAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Check if account exists
        bool exists = await accountExists(
            _emailController.text.trim(), _usernameController.text.trim());

        if (exists) {
          // ❌ If account exists, show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'This account already exists. Try different credentials.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // ✅ Add user to Firestore
        await _usersCollection.add({
          'email': _emailController.text.trim().toLowerCase(),
          'username': _usernameController.text.trim().toLowerCase(),
          'password': _passwordController.text.trim(),
          'createdAt': Timestamp.now(),
        });

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account successfully created!'),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ Navigate to sign-in page after successful account creation
        Navigator.pushReplacementNamed(context, '/signin');
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        print("❌ Error creating account: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title:
            const Text("Create Account", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ✅ Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: "Email", border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!isEmailValid(value)) {
                    return 'Please enter a valid email (@gmail.com, @yahoo.com, or @outlook.com)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ✅ Username Field
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                    labelText: "Username", border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.trim().length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ✅ Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Password", border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (!isPasswordStrong(value)) {
                    return 'Password must be at least 8 characters with uppercase, lowercase, number, and special character';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ✅ Create Account Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _createAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text("Create Account",
                          style: TextStyle(color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
