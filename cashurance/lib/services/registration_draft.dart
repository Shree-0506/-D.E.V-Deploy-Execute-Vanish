class RegistrationDraft {
  RegistrationDraft._();

  static final RegistrationDraft instance = RegistrationDraft._();

  String? fullName;
  String? phone;
  String? dob;
  String? address;
  String? pincode;
  String? idFrontPath;
  String? idBackPath;

  String? platform;
  String? platformWorkerId;
  String? upiId;
  String? password;

  void clear() {
    fullName = null;
    phone = null;
    dob = null;
    address = null;
    pincode = null;
    idFrontPath = null;
    idBackPath = null;
    platform = null;
    platformWorkerId = null;
    upiId = null;
    password = null;
  }
}
