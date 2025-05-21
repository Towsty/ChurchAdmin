class RolePermissions {
  static bool canTakeAttendance(String role) =>
      role.toLowerCase() == 'admin' || role.toLowerCase() == 'leader';

  static bool canExportAttendance(String role) =>
      role.toLowerCase() == 'admin' || role.toLowerCase() == 'leader';

  static bool canManageMeetingTypes(String role) =>
      role.toLowerCase() == 'admin';

  static bool canViewAttendance(String role) =>
      role.toLowerCase() == 'admin' || role.toLowerCase() == 'leader';

  static bool canApproveUsers(String role) => role.toLowerCase() == 'admin';

  static bool canAccessLandingPage(String role) =>
      role.toLowerCase() == 'admin' ||
      role.toLowerCase() == 'leader' ||
      role.toLowerCase() == 'member';

  static bool canManageJoinRequests(String role) =>
      role.toLowerCase() == 'admin';

  static bool canAccessAdminPortal(String role) =>
      role.toLowerCase() == 'admin';

  static bool canCreateSmallGroup(String role) =>
      role.toLowerCase() == 'admin' || role.toLowerCase() == 'leader';

  static bool canManageSmallGroup(
    String role,
    String userId,
    String leaderId,
  ) => role.toLowerCase() == 'admin' || userId == leaderId;

  static bool canManageSmallGroupMembers(
    String role,
    String userId,
    String leaderId,
  ) => role.toLowerCase() == 'admin' || userId == leaderId;

  static bool canDeleteSmallGroup(String role) => role.toLowerCase() == 'admin';
}
