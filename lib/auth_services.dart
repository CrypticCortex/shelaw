// lib/auth_services.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart'; // Import the config.dart file

/// A service class for authentication-related calls such as login, signup, logout, and user info.
class AuthServices {
  /// Logs in a user by sending their [email] and [password] to `/auth/login`.
  ///
  /// Returns a [Map] with:
  ///   - "success": boolean
  ///   - "message": string message (useful for display or debugging)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse("$apiBaseUrl/auth/login"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // If successful, store the access token in SharedPreferences
        if (data['access_token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('accessToken', data['access_token']);

          return {"success": true, "message": "Login successful"};
        } else {
          return {"success": false, "message": "No access token received"};
        }
      }

      return {
        "success": false,
        "message": "Login failed with status code ${response.statusCode}"
      };
    } catch (e) {
      // This block catches timeouts or any other network errors
      return {"success": false, "message": "Login error: $e"};
    }
  }

  /// Signs up a user by sending [email], [password], and [fullName] to `/auth/signup`.
  ///
  /// Returns a [Map] with:
  ///   - "success": boolean
  ///   - "message": string (e.g. success, error reason)
  Future<Map<String, dynamic>> signup(
      String email, String password, String fullName) async {
    try {
      final response = await http
          .post(
            Uri.parse("$apiBaseUrl/auth/signup"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {"email": email, "password": password, "full_name": fullName}),
          )
          .timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "message": data['message'] ?? "Signup successful"
        };
      } else {
        return {
          "success": false,
          "message": "Signup failed with status code ${response.statusCode}"
        };
      }
    } catch (e) {
      return {"success": false, "message": "Signup error: $e"};
    }
  }

  /// Logs out a user by removing all related keys from SharedPreferences.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('accessToken');
  }

  /// Fetches the currently authenticated user info (e.g., from `/auth/me`).
  ///
  /// Returns the user data as a [Map<String, dynamic>] if successful,
  /// or throws an exception if unauthorized or any error occurs.
  Future<Map<String, dynamic>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken == null) {
      // Not logged in or no token found
      throw Exception("No access token available.");
    }

    try {
      final response = await http.get(
        Uri.parse("$apiBaseUrl/auth/me"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        // Return the parsed JSON body
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            "Failed to fetch user info. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching user info: $e");
    }
  }

  /// Logs out the user on the server side by calling POST /auth/logout,
  /// then removes local token.
  /// Returns { "success": bool, "message": String }.
  Future<Map<String, dynamic>> logoutFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken == null) {
      return {"success": false, "message": "No access token found."};
    }

    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/auth/logout"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(Duration(seconds: requestTimeout));

      if (response.statusCode == 200) {
        // Successfully logged out on server side, remove local tokens
        await prefs.remove('isLoggedIn');
        await prefs.remove('accessToken');

        return {"success": true, "message": "Logout successful"};
      } else {
        return {
          "success": false,
          "message": "Logout failed with code ${response.statusCode}"
        };
      }
    } catch (e) {
      return {"success": false, "message": "Logout error: $e"};
    }
  }
}
