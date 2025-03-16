class UserModel {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;

  UserModel({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    this.createdAt,
    this.lastSignInAt,
  });

  // 从 Supabase User 创建 UserModel
  factory UserModel.fromSupabaseUser(dynamic user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      username: user.userMetadata?['username'],
      avatarUrl: user.userMetadata?['avatar_url'],
      createdAt: user.createdAt != null ? DateTime.parse(user.createdAt) : null,
      lastSignInAt: user.lastSignInAt != null ? DateTime.parse(user.lastSignInAt) : null,
    );
  }

  // 创建一个空的用户模型
  factory UserModel.empty() {
    return UserModel(
      id: '',
      email: '',
    );
  }

  // 复制并修改用户模型
  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastSignInAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    );
  }
} 