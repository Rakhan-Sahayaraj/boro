class Student {
  final int? id;
  final String name;
  final String regNo;
  final String collegeName;
  final String phone;
  final String? bikeModel;
  final String? bikeNumber;
  final bool hasBike;

  Student({
    this.id,
    required this.name,
    required this.regNo,
    required this.collegeName,
    required this.phone,
    this.bikeModel,
    this.bikeNumber,
    this.hasBike = false,
  });

  // Phone validation helper (10 digits)
  static bool isValidPhone(String phone) {
    return RegExp(r'^\d{10}$').hasMatch(phone);
  }

  // Bike Number validation helper (e.g., KA01AB1234 or KA 01 AB 1234)
  static bool isValidBikeNumber(String bikeNo) {
    final cleanNo = bikeNo.replaceAll(' ', '').toUpperCase();
    return RegExp(r'^[A-Z]{2}\d{2}[A-Z]{2}\d{4}$').hasMatch(cleanNo);
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'] ?? '',
      regNo: json['reg_no'] ?? json['username'] ?? '',
      collegeName: json['college_name'] ?? '',
      phone: json['phone'] ?? '',
      bikeModel: json['bike_model'],
      bikeNumber: json['bike_number'],
      hasBike: json['has_bike'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'reg_no': regNo,
      'college_name': collegeName,
      'phone': phone,
      'password': '',
      'bike_model': bikeModel ?? '',
      'bike_number': bikeNumber ?? '',
    };
  }
}