import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fungsi untuk Register
  Future<String?> register(String name, String email, String password) async {
    try {
      // 1. Membuat akun di Firebase Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Menyimpan data profil ke Cloud Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': name,
            'email': email,
            'phone': '',
            'photoUrl': '',
            'created_at': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 10));

      return null; // Sukses
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'Password terlalu lemah (minimal 6 karakter).';
      if (e.code == 'email-already-in-use') return 'Email sudah terdaftar. Silakan login.';
      if (e.code == 'invalid-email') return 'Format email tidak valid.';
      return e.message ?? 'Registrasi gagal.';
    } catch (e) {
      return 'Gagal terhubung ke database. Pastikan koneksi internet aktif.';
    }
  }

  // Fungsi untuk Login
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Email atau password yang Anda masukkan salah.';
      }
      if (e.code == 'invalid-email') return 'Format email tidak valid.';
      if (e.code == 'network-request-failed') return 'Koneksi internet bermasalah. Periksa koneksi Anda.';
      return e.message ?? 'Login gagal. Silakan coba lagi.';
    } catch (e) {
      return e.toString();
    }
  }

  // Current User
  User? get currentUser => _auth.currentUser;

  // Fungsi untuk Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Fungsi untuk mengambil data profil user yang sedang login
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      // Ignored
    }
    return null;
  }
}
