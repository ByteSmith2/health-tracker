import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Create a new account with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Continue without account (anonymous sign-in)
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// Check if user is anonymous
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  /// Link anonymous account with email/password (keeps all data)
  Future<UserCredential> linkWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    return await _auth.currentUser!.linkWithCredential(credential);
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get a Vietnamese error message from FirebaseAuthException
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Sai mật khẩu. Vui lòng thử lại.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Cần ít nhất 6 ký tự.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng đợi một lát.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Kiểm tra internet.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      default:
        return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    }
  }
}
