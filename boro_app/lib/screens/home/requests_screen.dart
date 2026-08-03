import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'chat_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    final reqs = await ApiService.getIncomingRequests();
    if (mounted) {
      setState(() {
        _requests = reqs;
        _isLoading = false;
      });
    }
  }

  void _accept(int requestId) async {
    bool ok = await ApiService.acceptRequest(requestId);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking Accepted! You can now chat.')),
      );
      _fetchRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Incoming Ride Requests'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reload Requests',
            onPressed: _fetchRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _fetchRequests,
              color: Colors.black,
              backgroundColor: Colors.white,
              child: _requests.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No pending requests right now.\n\nPull down or tap 🔄 to refresh.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final req = _requests[index];
                        final bookingId = req['id'] ?? req['booking_id'];
                        final status = (req['status'] ?? 'Pending').toString();
                        final isAccepted = status.toLowerCase() == 'accepted';
                        final passengerName = req['passenger_name'] ?? 'Passenger #${req['passenger_id'] ?? ''}';

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
                                      'Request #${bookingId}',
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
                                          color: isAccepted ? Colors.greenAccent : Colors.amberAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: Colors.black.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ride ID: ${req['ride_id']} | Passenger: $passengerName',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    // ACCEPT BUTTON (Show if pending)
                                    if (!isAccepted)
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _accept(bookingId),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('ACCEPT REQUEST', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),

                                    // CHAT BUTTON (Show if accepted)
                                    if (isAccepted)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ChatScreen(
                                                  bookingId: bookingId, // Same matched Booking ID!
                                                  isHost: true,
                                                  otherUserName: passengerName,
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