import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'chat_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<dynamic> _myRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyRequests();
  }

  Future<void> _fetchMyRequests() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getMyRequests();
    if (mounted) {
      setState(() {
        _myRequests = list;
        _isLoading = false;
      });
    }
  }

  void _cancel(int requestId) async {
    bool ok = await ApiService.cancelBooking(requestId);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking Cancelled')),
      );
      _fetchMyRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('My Requested Rides'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reload Bookings',
            onPressed: _fetchMyRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _fetchMyRequests,
              color: Colors.black,
              backgroundColor: Colors.white,
              child: _myRequests.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No active bookings found.\n\nPull down or tap 🔄 to refresh.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _myRequests.length,
                      itemBuilder: (context, index) {
                        final item = _myRequests[index];
                        final bookingId = item['id'] ?? item['booking_id'];
                        final status = (item['status'] ?? 'Pending').toString();
                        final isAccepted = status.toLowerCase() == 'accepted';
                        final isCancelledOrRejected = status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'rejected';

                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Booking #${bookingId}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: isAccepted
                                              ? Colors.greenAccent
                                              : isCancelledOrRejected
                                                  ? Colors.redAccent
                                                  : Colors.amberAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: Colors.black.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ride ID: ${item['ride_id']}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    // CHAT BUTTON (Enabled when Accepted)
                                    if (isAccepted)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ChatScreen(
                                                  bookingId: bookingId, // Matched Booking ID!
                                                  isHost: false,
                                                  otherUserName: item['host_name'] ?? 'Host Driver',
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.chat),
                                          label: const Text('Chat & Price'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                          ),
                                        ),
                                      ),
                                    if (isAccepted && !isCancelledOrRejected) const SizedBox(width: 12),
                                    
                                    // CANCEL BUTTON
                                    if (!isCancelledOrRejected)
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _cancel(bookingId),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: const BorderSide(color: Colors.redAccent),
                                          ),
                                          child: const Text('Cancel Request'),
                                        ),
                                      ),
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