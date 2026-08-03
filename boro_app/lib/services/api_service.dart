import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://boro-backend.onrender.com';
    }
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  // --- GET USER PROFILE (CHECKS SAVED BIKE DETAILS) ---
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('--> Fetch Profile Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Fetch profile error: $e');
    }
    return null;
  }

  // --- LOGIN ---
  static Future<bool> login(String regNo, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': regNo.trim(),
          'password': password.trim(),
        },
      );

      debugPrint('--> Login Status: ${response.statusCode}');
      debugPrint('--> Login Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        if (token != null) {
          await StorageService.saveToken(token);
          return true;
        }
      }
    } catch (e) {
      debugPrint('--> Login Exception: $e');
    }
    return false;
  }

  // --- REGISTER ---
  static Future<Map<String, dynamic>> register(Map<String, dynamic> studentData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(studentData),
      );

      debugPrint('--> Register Status: ${response.statusCode}');
      debugPrint('--> Register Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        String errorMsg = 'Registration failed (${response.statusCode})';
        if (error['detail'] != null) {
          if (error['detail'] is String) {
            errorMsg = error['detail'];
          } else if (error['detail'] is List && error['detail'].isNotEmpty) {
            errorMsg = error['detail'][0]['msg'] ?? errorMsg;
          }
        }
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      debugPrint('--> Register Exception: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  // --- UPDATE BIKE DETAILS (UNLOCK HOST MODE) ---
  static Future<bool> updateBikeDetails(String model, String number) async {
    try {
      final token = await StorageService.getToken();
      
      // Strips extra spaces & ensures uppercase plate formatting
      final formattedNumber = number.replaceAll(' ', '').toUpperCase().trim();

      final response = await http.put(
        Uri.parse('$baseUrl/auth/update-bike'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'has_bike': true,
          'bike_model': model.trim(),
          'bike_number': formattedNumber,
        }),
      );

      debugPrint('--> Update Bike Status: ${response.statusCode}');
      debugPrint('--> Update Bike Response: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('--> Update bike error: $e');
      return false;
    }
  }

  // --- LOGOUT & CLEANUP ---
  static Future<void> logout() async {
    try {
      final token = await StorageService.getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/ride/logout-cleanup'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
    } catch (e) {
      debugPrint('Logout cleanup error: $e');
    } finally {
      await StorageService.deleteToken();
    }
  }

  // --- GET ALL RIDES (PASSENGER SCREEN) ---
  static Future<List<dynamic>> getAllRides() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/ride/all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Fetch all rides error: $e');
    }
    return [];
  }

  // --- GET MY RIDES (HOST SCREEN) ---
  static Future<List<dynamic>> getMyRides() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/ride/my'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Fetch my rides error: $e');
    }
    return [];
  }

  // --- POST A RIDE ---
  static Future<bool> postRide(Map<String, dynamic> rideData) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/ride/post'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(rideData),
      );

      debugPrint('--> Post Ride Status: ${response.statusCode}');
      debugPrint('--> Post Ride Response: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Post ride error: $e');
      return false;
    }
  }

  // --- UPDATE A RIDE ---
  static Future<bool> updateRide(int rideId, Map<String, dynamic> rideData) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/ride/$rideId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(rideData),
      );

      debugPrint('--> Update Ride Status: ${response.statusCode}');
      debugPrint('--> Update Ride Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update ride error: $e');
      return false;
    }
  }

  // --- DELETE A RIDE ---
  static Future<bool> deleteRide(int rideId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/ride/$rideId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('--> Delete Ride Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete ride error: $e');
      return false;
    }
  }

  // --- REQUEST A RIDE ---
  static Future<Map<String, dynamic>> requestRide(int rideId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/booking/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'ride_id': rideId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Request sent!'};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Failed to request ride'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // --- INCOMING REQUESTS (HOST) ---
  static Future<List<dynamic>> getIncomingRequests() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/booking/ride-requests'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Fetch requests error: $e');
    }
    return [];
  }

  // --- ACCEPT REQUEST ---
  static Future<bool> acceptRequest(int requestId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/booking/accept/$requestId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- MY REQUESTS (PASSENGER) ---
  static Future<List<dynamic>> getMyRequests() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/booking/my-requests'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : (data['requests'] ?? []);
      }
    } catch (e) {
      debugPrint('Fetch my requests error: $e');
    }
    return [];
  }

  // --- CANCEL BOOKING ---
  static Future<bool> cancelBooking(int requestId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/booking/cancel/$requestId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- NOTIFICATIONS ---
  static Future<List<dynamic>> getNotifications() async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/notification/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['notifications'] ?? [];
      }
    } catch (e) {
      debugPrint('Fetch notifications error: $e');
    }
    return [];
  }

  // ==========================================
  // --- CHAT & MONEY PROPOSAL ENDPOINTS ---
  // ==========================================

  // --- GET CHAT MESSAGES FOR A SPECIFIC BOOKING ---
  static Future<List<dynamic>> getChatMessages(int bookingId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/$bookingId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('--> Fetch Chat Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : (data['messages'] ?? []);
      }
    } catch (e) {
      debugPrint('Fetch chat error: $e');
    }
    return [];
  }

  // --- SEND CHAT MESSAGE ---
  static Future<bool> sendMessage(int bookingId, String text) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'booking_id': bookingId,
          'message': text.trim(),
        }),
      );

      debugPrint('--> Send Message Status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Send message error: $e');
      return false;
    }
  }

  // --- SEND PRICE PROPOSAL (FAREGOTIATION) ---
  static Future<bool> sendPriceProposal(int bookingId, double amount) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/propose-price'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'booking_id': bookingId,
          'proposed_price': amount,
        }),
      );

      debugPrint('--> Send Proposal Status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Send price proposal error: $e');
      return false;
    }
  }

  // --- ACCEPT OR REJECT PROPOSAL ---
  static Future<bool> respondToProposal(int proposalId, bool accept) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/chat/proposal/$proposalId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': accept ? 'accepted' : 'rejected'}),
      );

      debugPrint('--> Respond Proposal Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Respond to proposal error: $e');
      return false;
    }
  }
}