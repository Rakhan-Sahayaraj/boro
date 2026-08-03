class Ride {
  final int? id;
  final String fromPlace;
  final String toPlace;
  final String rideDate;
  final String rideTime;
  final int availableSeats;
  final double price;
  final String? message;
  final bool helmet;
  final String? status;

  Ride({
    this.id,
    required this.fromPlace,
    required this.toPlace,
    required this.rideDate,
    required this.rideTime,
    this.availableSeats = 1,
    this.price = 0.0,
    this.message,
    this.helmet = true,
    this.status = 'Available',
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] ?? json['ride_id'],
      fromPlace: json['from_place'] ?? json['from_location'] ?? '',
      toPlace: json['to_place'] ?? json['to_location'] ?? '',
      rideDate: json['ride_date'] ?? json['date'] ?? '',
      rideTime: json['ride_time'] ?? json['time'] ?? '',
      availableSeats: json['available_seats'] ?? json['available_seat'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
      message: json['message'],
      helmet: json['helmet'] ?? json['helmet_provided'] ?? true,
      status: json['status'] ?? 'Available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'from_place': fromPlace,
      'to_place': toPlace,
      'ride_date': rideDate,
      'ride_time': rideTime,
      'available_seats': availableSeats,
      'price': price,
      'message': message ?? '',
      'helmet': helmet,
    };
  }
}