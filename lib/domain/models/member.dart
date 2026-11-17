/// A logged-in team member. Transactions are recorded under their name.
class Member {
  const Member({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;

  /// Shown in the history and on the profile, e.g. "Ola Nowak".
  final String displayName;

  Member copyWith({String? id, String? email, String? displayName}) => Member(
    id: id ?? this.id,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
  );

  @override
  bool operator ==(Object other) =>
      other is Member &&
      other.id == id &&
      other.email == email &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(id, email, displayName);
}
