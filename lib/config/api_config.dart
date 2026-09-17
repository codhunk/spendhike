/// Central Helper Configuration File for Backend API Endpoints.
///
/// To point the app to a different backend server (e.g., local dev, staging, production),
/// simply update [serverUrl] in this helper file. All API requests across the application
/// will automatically update.
class ApiConfig {
  /// Primary backend server base URL hosted on Render.
  static const String serverUrl = 'https://spendhike-server.onrender.com';

  /// Full base API endpoint URL (v1)
  static String get baseUrl => '$serverUrl/api/v1';

  /// Backend health check endpoint URL
  static String get healthUrl => '$serverUrl/health';

  /// Authentication endpoints
  static String get registerUrl => '$serverUrl/api/v1/auth/register';
  static String get loginUrl => '$serverUrl/api/v1/auth/login';
  static String get logoutUrl => '$serverUrl/api/v1/auth/logout';
  static String get googleAuthUrl => '$serverUrl/api/v1/auth/google';

  /// User endpoints
  static String get currentUserUrl => '$serverUrl/api/v1/users/me';

  /// Transactions endpoints
  static String get transactionsUrl => '$serverUrl/api/v1/transactions';
  static String transactionUrl(String id) => '$serverUrl/api/v1/transactions/$id';

  /// Project Group endpoints
  static String get groupsUrl => '$serverUrl/api/v1/groups';
  static String groupUrl(String id) => '$serverUrl/api/v1/groups/$id';
  static String get groupTransactionsUrl => '$serverUrl/api/v1/groups/transactions';

  /// Reports endpoints
  static String get profitAndLossUrl => '$serverUrl/api/v1/reports/profit-loss';
  static String get categoryBreakdownUrl => '$serverUrl/api/v1/reports/categories';
  static String get dashboardSummaryUrl => '$serverUrl/api/v1/reports/dashboard';

  /// Candidate URLs used for probing server availability across platforms
  static List<String> get candidateUrls => [
        '$serverUrl/api/v1',
      ];
}
