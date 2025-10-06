class User {
  String name;
  final String email;
  String? avatarUrl; // For a profile picture

  User({
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  // Fix: Add copyWith for easy state updates
  User copyWith({
    String? name,
    String? avatarUrl,
  }) {
    return User(
      name: name ?? this.name,
      email: this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json['name'] as String? ?? '',
    email: json['email'] as String,
    avatarUrl: json['avatarUrl'] as String?,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
  };
}
