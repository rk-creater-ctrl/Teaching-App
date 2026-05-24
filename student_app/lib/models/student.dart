class Student {
  final String id;
  final String fullName;
  final String email;
  final String username;
  final String role;

  Student({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    required this.role,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? json['email'] ?? '',
      role: json['role'] ?? 'student',
    );
  }

  Student copyWith({
    String? id,
    String? fullName,
    String? email,
    String? username,
    String? role,
  }) {
    return Student(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
    );
  }
}
