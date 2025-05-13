class RolePermissions {
  static bool canTakeAttendance(String role) =>
      role == 'Admin' || role == 'Leader';

  static bool canExportAttendance(String role) =>
      role == 'Admin' || role == 'Leader';

  static bool canManageMeetingTypes(String role) =>
      role == 'Admin';

  static bool canViewAttendance(String role) =>
      role == 'Admin' || role == 'Leader';

  static bool canApproveUsers(String role) =>
      role == 'Admin';

  static bool canAccessLandingPage(String role) =>
      role == 'Admin' || role == 'Leader' || role == 'Member';
}
