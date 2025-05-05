class AppConstants {
  static const String appName = 'IIC Connect';
  static const String universityName = 'University of Delhi';
  static const String departmentName = 'Institute of Informatics and Communication';

  // API endpoints
  static const String baseUrl = 'https://api.iic.du.ac.in';
  static const String noticesEndpoint = '/notices';
  static const String timetableEndpoint = '/timetable';
  static const String attendanceEndpoint = '/attendance';
  static const String projectsEndpoint = '/projects';
  static const String labsEndpoint = '/labs';
  static const String eventsEndpoint = '/events';

  // SharedPreferences keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String userRoleKey = 'user_role';

  // User roles
  static const String studentRole = 'student';
  static const String facultyRole = 'faculty';
  static const String staffRole = 'staff';
  static const String adminRole = 'admin';
}