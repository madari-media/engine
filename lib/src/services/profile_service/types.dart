class UserProfile {
  final String id;
  final String name;
  final String? profileImage;
  final bool canSearch;

  UserProfile({
    required this.id,
    required this.name,
    this.profileImage,
    this.canSearch = true,
  });
}
