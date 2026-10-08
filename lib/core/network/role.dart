/// Mirrors `users.status` from the legacy schema (see lootapp-api/src/config/roles.js).
/// Kept as string-coded values rather than renumbered, since the backend
/// treats them as stored data.
enum AppRole {
  unverified,
  affiliate,
  manager,
  admin;

  static AppRole fromStatus(String status) {
    switch (status) {
      case '1':
        return AppRole.affiliate;
      case '9':
        return AppRole.manager;
      case '69':
        return AppRole.admin;
      default:
        return AppRole.unverified;
    }
  }
}
