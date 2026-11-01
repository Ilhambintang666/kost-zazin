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

      // 2. Menyimpan data profil ke Cloud Firestore dengan batas waktu (timeout) 10 detik
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': name,
            'email': email,
            'phone': '',
            'photoUrl': '',
          })
          .timeout(const Duration(seconds: 10));

      return null; // Sukses
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Gagal terhubung ke database. Pastikan Firestore sudah diaktifkan.";
    }
  }

  // Fungsi untuk Login
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
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
      print("Error fetching user data: $e");
    }
    return null;
  }
}

