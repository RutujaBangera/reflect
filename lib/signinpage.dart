import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Reference to the users collection in Firestore
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // ✅ Function to validate credentials against Firestore
  Future<bool> isValidAccount(String username, String password) async {
    try {
      // Query Firestore for matching username
      QuerySnapshot querySnapshot = await _usersCollection
          .where('username', isEqualTo: username.toLowerCase().trim())
          .get();

      // Check if we found a user and if password matches
      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        if (userData['password'] == password) {
          return true;
        }
      }

      // If we're here, either username doesn't exist or password doesn't match
      return false;
    } catch (e) {
      print("❌ Error validating account: $e");
      return false;
    }
  }

  // ✅ Save user to SharedPreferences
  Future<void> _saveUserToPrefs(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', username);
      print("✅ User saved to SharedPreferences: $username");
    } catch (e) {
      print("❌ Error saving user to SharedPreferences: $e");
    }
  }

  // ✅ Sign-In Logic
  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String username = _usernameController.text.trim();
        String password = _passwordController.text.trim();

        bool isValid = await isValidAccount(username, password);

        setState(() => _isLoading = false);

        if (isValid) {
          // ✅ Save user to SharedPreferences before navigation
          await _saveUserToPrefs(username);

          // ✅ Success -> Go to Home Page
          Navigator.pushReplacementNamed(context, '/home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // ❌ Error -> Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid username or password'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text(
          "Sign In",
          style: TextStyle(color: Colors.white),
        ),
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
              // ✅ Username Field
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
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
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ✅ Sign In Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Sign In",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
