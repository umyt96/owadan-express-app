class UserProfile {
  final String? number;
  final DateTime? createdDate;

  UserProfile({this.number, this.createdDate});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      number: json['number'],
      createdDate: json['created_date'] != null
          ? DateTime.tryParse(json['created_date'])
          : null,
    );
  }
}

class AppUser {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final UserProfile? profile;
  final bool isSuperuser;
  final bool isStaff;

  /// Доступ к разделу "Товары" (добавление/изменение) — персонал и суперпользователь.
  bool get canManageProducts => isStaff || isSuperuser;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profile,
    this.isSuperuser = false,
    this.isStaff = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'])
          : null,
      isSuperuser: json['is_superuser'] ?? false,
      isStaff: json['is_staff'] ?? false,
    );
  }
}
