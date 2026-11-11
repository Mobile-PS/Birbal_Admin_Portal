import '../../core/utils/json_utils.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;

  String get displayName {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'Admin' : trimmed;
  }

  String get firstName {
    final trimmed = displayName;
    return trimmed.split(' ').first;
  }

  factory UserModel.fromJson(Map<String, dynamic> json, {String? phone}) {
    final first = jsonNullableString(json['firstName'] ?? json['first_name']);
    final last = jsonNullableString(json['lastName'] ?? json['last_name']);
    final composedName = [
      ?first,
      ?last,
    ].join(' ').trim();

    return UserModel(
      id: jsonString(
        json['userPublicId'] ?? json['id'] ?? json['user_id'],
      ),
      name: composedName.isNotEmpty
          ? composedName
          : jsonString(
              json['name'] ?? json['full_name'] ?? json['fullName'],
              fallback: 'Admin',
            ),
      email: jsonNullableString(json['email']),
      phone: phone ?? jsonNullableString(json['phone'] ?? json['mobile']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
}
