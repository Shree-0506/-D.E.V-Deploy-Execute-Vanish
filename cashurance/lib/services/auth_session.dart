class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  String? token;
  int? workerId;
  String? fullName;
  String? phone;
  bool firstTimeSetup = true;

  bool get isAuthenticated => token != null && workerId != null;

  void setSession({
    required String token,
    required int workerId,
    required String fullName,
    required String phone,
    required bool firstTimeSetup,
  }) {
    this.token = token;
    this.workerId = workerId;
    this.fullName = fullName;
    this.phone = phone;
    this.firstTimeSetup = firstTimeSetup;
  }

  void clear() {
    token = null;
    workerId = null;
    fullName = null;
    phone = null;
    firstTimeSetup = true;
  }
}
