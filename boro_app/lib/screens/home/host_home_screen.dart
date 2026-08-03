import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'requests_screen.dart';
import 'chat_screen.dart';

class HostHomeScreen extends StatefulWidget {
  const HostHomeScreen({super.key});

  @override
  State<HostHomeScreen> createState() => _HostHomeScreenState();
}

class _HostHomeScreenState extends State<HostHomeScreen> {
  List<dynamic> _myRides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyRides();
  }

  Future<void> _fetchMyRides() async {
    setState(() => _isLoading = true);
    final rides = await ApiService.getMyRides();
    if (mounted) {
      setState(() {
        _myRides = rides;
        _isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    await ApiService.logout(); // Triggers backend cleanup and deletes token
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _confirmDelete(int rideId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Ride', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this ride posting?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = await ApiService.deleteRide(rideId);
              if (success && mounted) {
                _fetchMyRides();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ride deleted successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPostOrEditRideModal({Map<String, dynamic>? existingRide}) {
    final isEditing = existingRide != null;

    final fromController = TextEditingController(
        text: isEditing ? (existingRide['from_place'] ?? '') : '');
    final toController = TextEditingController(
        text: isEditing ? (existingRide['to_place'] ?? '') : '');
    final dateController = TextEditingController(
        text: isEditing ? (existingRide['ride_date'] ?? '2026-08-02') : '2026-08-02');
    final timeController = TextEditingController(
        text: isEditing ? (existingRide['ride_time'] ?? '09:00 AM') : '09:00 AM');

    bool helmet = isEditing ? (existingRide['helmet'] ?? true) : true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing ? 'Change / Edit Ride' : 'Post a New Ride',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: fromController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'From Location',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: toController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'To Location',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dateController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Date (YYYY-MM-DD)',
                              labelStyle: TextStyle(color: Colors.grey),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: timeController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Time (e.g. 09:00 AM)',
                              labelStyle: TextStyle(color: Colors.grey),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Helmet Provided for Pillion?', style: TextStyle(color: Colors.white)),
                      value: helmet,
                      activeColor: Colors.white,
                      onChanged: (val) => setModalState(() => helmet = val),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (fromController.text.isEmpty || toController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill in locations')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final rideData = {
                                "from_place": fromController.text.trim(),
                                "to_place": toController.text.trim(),
                                "ride_date": dateController.text.trim(),
                                "ride_time": timeController.text.trim(),
                                "helmet": helmet,
                              };

                              bool success = false;
                              if (isEditing) {
                                final rideId = existingRide['id'] ?? existingRide['ride_id'];
                                success = await ApiService.updateRide(rideId, rideData);
                              } else {
                                success = await ApiService.postRide(rideData);
                              }

                              setModalState(() => isSubmitting = false);

                              if (success && mounted) {
                                Navigator.pop(ctx);
                                _fetchMyRides();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEditing
                                        ? 'Ride updated successfully!'
                                        : 'Ride posted successfully!'),
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Operation failed. Please try again.')),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : Text(isEditing ? 'UPDATE RIDE' : 'POST RIDE', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveRide = _myRides.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('BORO - Host Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        actions: [
          // RELOAD / REFRESH BUTTON
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reload',
            onPressed: _fetchMyRides,
          ),
          IconButton(
            icon: const Icon(Icons.inbox),
            tooltip: 'Ride Requests',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RequestsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      floatingActionButton: hasActiveRide
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showPostOrEditRideModal(),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Post Ride', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _fetchMyRides,
              color: Colors.black,
              backgroundColor: Colors.white,
              child: _myRides.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'You haven\'t posted a ride yet.\nTap "+ Post Ride" to offer a ride.\n(Only 1 active ride allowed per host)\n\nPull down or tap 🔄 to refresh.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _myRides.length,
                      itemBuilder: (context, index) {
                        final ride = _myRides[index];
                        final rideId = ride['id'] ?? ride['ride_id'];
                        final activeBookingId = ride['booking_id'] ?? rideId; // Prefers booking_id for chat thread matching
                        final fromLoc = ride['from_place'] ?? '';
                        final toLoc = ride['to_place'] ?? '';
                        final rideDate = ride['ride_date'] ?? '';
                        final status = (ride['status'] ?? 'Available').toString();

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
                                    Expanded(
                                      child: Text(
                                        '$fromLoc ➔ $toLoc',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text(
                                            status.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.amber,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          backgroundColor: Colors.black.withOpacity(0.25),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () => _confirmDelete(rideId),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Date: $rideDate | Two-Wheeler Ride',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showPostOrEditRideModal(existingRide: ride),
                                        icon: const Icon(Icons.edit, color: Colors.white),
                                        label: const Text('Change Ride', style: TextStyle(color: Colors.white)),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                bookingId: activeBookingId, // Pass bookingId instead of rideId
                                                isHost: true,
                                                otherUserName: 'Pillion Rider',
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
                                )
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