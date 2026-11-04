import 'package:equatable/equatable.dart';

enum UserRole {
  admin,
  user,
}

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final int points;
  final int freeQuota;
  final int adsWatched;
  final List<String> joinedProjects;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role = UserRole.user,
    this.points = 0,
    this.freeQuota = 10,
    this.adsWatched = 0,
    this.joinedProjects = const [],
  });
  
  // Factory for creating from Firebase User (would be in data layer logically, but here for convenience or keeping domain pure? Keeping domain pure.)
  
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    int? points,
    int? freeQuota,
    int? adsWatched,
    List<String>? joinedProjects,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      points: points ?? this.points,
      freeQuota: freeQuota ?? this.freeQuota,
      adsWatched: adsWatched ?? this.adsWatched,
      joinedProjects: joinedProjects ?? this.joinedProjects,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, role, points, freeQuota, adsWatched, joinedProjects];
  
  // JSON serialization helpers could go here or in a helper/extension
}
