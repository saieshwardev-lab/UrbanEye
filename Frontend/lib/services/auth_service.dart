class AuthService {
  // Simple in-memory user state for mock
  static bool _signedIn = false;
  static String? _userName;
  static String? _userEmail;

  // Expose simple flags
  static bool get isSignedIn => _signedIn;
  static String get currentUserName => _userName ?? 'Guest';
  static String get currentUserEmail => _userEmail ?? '';

  // Initialize placeholder (use SharedPreferences or secure storage later)
  static Future<void> initialize() async {
    // nothing for now — placeholder to support async init
    await Future.delayed(Duration(milliseconds: 1));
  }

  // Mock register: succeed unless email already contains "taken"
  static Future<bool> register({required String name, required String email, required String password}) async {
    await Future.delayed(Duration(milliseconds: 700)); // simulate network
    if (email.contains('taken')) return false;
    _signedIn = true;
    _userName = name;
    _userEmail = email;
    return true;
  }

  // Mock sign-in: accept any password except "wrong"
  static Future<bool> signIn({required String email, required String password}) async {
    await Future.delayed(Duration(milliseconds: 700));
    if (password == 'wrong') return false;
    _signedIn = true;
    _userName = email.split('@').first;
    _userEmail = email;
    return true;
  }

  static void signInAsGuest() {
    _signedIn = true;
    _userName = 'Guest';
    _userEmail = '';
  }

  static void signOut() {
    _signedIn = false;
    _userName = null;
    _userEmail = null;
  }
}
