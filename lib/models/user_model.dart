// models/user_model.dart

class User {
  final String? id;
  final String namaLengkap;
  final String email;
  final String password;
  final String? phoneNumber;
  final String? profilPicture;

  User({
    this.id,
    required this.namaLengkap,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.profilPicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id_user'],
      namaLengkap: json['nama_lengkap'],
      email: json['email'],
      password: json['password'],
      phoneNumber: json['phone_number'],
      profilPicture: json['profil_picture'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'nama_lengkap': namaLengkap,
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'profil_picture': profilPicture,
    };
    
    if (id != null) {
      map['id_user'] = id;
    }
    
    return map;
  }

  User copyWith({
    String? id,
    String? namaLengkap,
    String? email,
    String? password,
    String? phoneNumber,
    String? profilPicture,
  }) {
    return User(
      id: id ?? this.id,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilPicture: profilPicture ?? this.profilPicture,
    );
  }
}