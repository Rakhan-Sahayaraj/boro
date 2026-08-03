import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'my_bookings_screen.dart';
import 'notifications_screen.dart';
import 'chat_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  List<dynamic> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAvailableRides();
  }

  Future<void> _fetchAvailableRides() async {
    setState(() => _isLoading = true);
    final rides = await ApiService.getAllRides();
    if (mounted) {
      setState(() {
        _rides = rides;
        _isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('BORO - Find a Ride', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        actions: [
          // RELOAD / REFRESH BUTTON
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reload Rides',
            onPressed: _fetchAvailableRides,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'My Bookings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _fetchAvailableRides,
              color: Colors.black,
              backgroundColor: Colors.white,
              child: _rides.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No available rides found right now.\n\nPull down or tap 🔄 to refresh.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _rides.length,
                      itemBuilder: (context, index) {
                        final ride = _rides[index];
                        final rideId = ride['id'] ?? ride['ride_id'];
                        final activeBookingId = ride['booking_id'] ?? rideId; // Updated to bookingId
                        final fromLoc = ride['from_location'] ?? ride['from_place'] ?? '';
                        final toLoc = ride['to_location'] ?? ride['to_place'] ?? '';
                        final rideDate = ride['date'] ?? ride['ride_date'] ?? '';
                        final rideTime = ride['time'] ?? ride['ride_time'] ?? '';
                        final hasHelmet = ride['helmet'] ?? true;

                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$fromLoc ➔ $toLoc',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Date: $rideDate | Time: $rideTime',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Helmet Provided: ${hasHelmet ? "Yes 🪖" : "No"}',
                                  style: TextStyle(
                                    color: hasHelmet ? Colors.greenAccent : Colors.amberAccent,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                        ),
                                        onPressed: () async {
                                          if (rideId != null) {
                                            final result = await ApiService.requestRide(rideId);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(result['message'])),
                                              );
                                              _fetchAvailableRides();
                                            }
                                          }
                                        },
                                        child: const Text('REQUEST RIDE', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.chat, color: Colors.white),
                                      tooltip: 'Chat & Negotiate Price',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              bookingId: activeBookingId, // Updated parameter name from rideId to bookingId
                                              isHost: false, // Pillion view
                                              otherUserName: 'Host Driver',
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}