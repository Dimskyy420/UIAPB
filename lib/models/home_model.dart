class HomeModel {
  final String displayName;
  final String? photoUrl;
  final String email;
 
  HomeModel({
    required this.displayName,
    required this.photoUrl,
    required this.email,
  });
 
  String get firstName => displayName.split(' ').first;
 
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  }
}