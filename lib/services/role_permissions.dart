class RolePermissions {
  static bool isSuper(String role) => role.toLowerCase() == 'super';

  static bool canTakeAttendance(String role) =>
      isSuper(role) ||
      role.toLowerCase() == 'admin' ||
      role.toLowerCase() == 'leader';

  static bool canExportAttendance(String role) =>
      isSuper(role) ||
      role.toLowerCase() == 'admin' ||
      role.toLowerCase() == 'leader';

  static bool canManageMeetingTypes(String role) =>
      isSuper(role) || role.toLowerCase() == 'admin';

  static bool canViewAttendance(String role) =>
      isSuper(role) ||
      role.toLowerCase() == 'admin' ||
      role.toLowerCase() == 'leader';

  static bool canApproveUsers(String role) =>
      isSuper(role) || role.toLowerCase() == 'admin';

  static bool canAccessLandingPage(String role) =>
      isSuper(role) ||
      role.toLowerCase() == 'admin' ||
      role.toLowerCase() == 'leader' ||
      role.toLowerCase() == 'member';

  static bool canManageJoinRequests(String role) =>
      isSuper(role) || role.toLowerCase() == 'admin';

  static bool canAccessAdminPortal(String role) =>
      isSuper(role) || role.toLowerCase() == 'admin';

  static bool canCreateSmallGroup(String role) =>
      isSuper(role) ||
      role.toLowerCase() == 'admin' ||
      role.toLowerCase() == 'leader';

  static bool canManageSmallGroup(
    String role,
    String userId,
    String leaderId,
  ) =>
      isSuper(role) || role.toLowerCase() == 'admin' || userId == leaderId;

  static bool canManageSmallGroupMembers(
    String role,
    String userId,
    String leaderId,
  ) =>
      isSuper(role) || role.toLowerCase() == 'admin' || userId == leaderId;

  static bool canDeleteSmallGroup(String role) =>
      isSuper(role) || role.toLowerCase() == 'admin';

  static bool canAccessSuperAdmin(String role) => isSuper(role);
}
