// lib/providers/auth_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arbolitos/services/firebase_service.dart';
import 'package:uuid/uuid.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  User? _user;
  AuthStatus _status = AuthStatus.uninitialized;
  String _errorMessage = '';
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  
  // Getters
  User? get user => _user;
  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _status == AuthStatus.authenticated; // <-- CORREGIDO
  
  // Constructor
  AuthProvider() {
    // Escuchar cambios en autenticación
    _firebaseService.auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  // Método para manejar cambios en estado de autenticación
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      _userData = null;
    } else {
      _user = firebaseUser;
      _status = AuthStatus.authenticated;
      
      // Obtener datos adicionales del usuario desde Firestore
      try {
        DocumentSnapshot doc = await _firebaseService.getUserData(firebaseUser.uid);
        if (doc.exists) {
          _userData = doc.data() as Map<String, dynamic>;
        }
      } catch (e) {
        print('Error al obtener datos de usuario: $e');
      }
    }
    
    notifyListeners();
  }
  
  // Iniciar sesión con email y contraseña
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      await _firebaseService.signInWithEmailAndPassword(email, password);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }
  
  // Registrarse con email y contraseña
  Future<bool> registerWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      UserCredential userCredential = await _firebaseService.createUserWithEmailAndPassword(email, password);
      
      // Guardar datos iniciales del usuario
      await _firebaseService.saveUserData(userCredential.user!.uid, {
        'uid': userCredential.user!.uid,
        'email': email,
        'creadoEn': FieldValue.serverTimestamp()
      });
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // --- MÉTODO AÑADIDO PARA GOOGLE SIGN-IN ---
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      UserCredential userCredential = await _firebaseService.signInWithGoogle();
      
      // Si el usuario es nuevo, guardar sus datos en Firestore
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        User user = userCredential.user!;
        await _firebaseService.saveUserData(user.uid, {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'creadoEn': FieldValue.serverTimestamp(),
        });
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }
  
  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión';
      notifyListeners();
    }
  }
  
  // Restablecer contraseña
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      await _firebaseService.resetPassword(email);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }
  
  // Método para manejar errores de autenticación
  String _handleAuthError(dynamic e) {
    String errorMessage = 'Ocurrió un error inesperado';
    
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'El correo electrónico no es válido';
          break;
        case 'user-disabled':
          errorMessage = 'Esta cuenta ha sido deshabilitada';
break;
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este correo electrónico';
          break;
        case 'wrong-password':
          errorMessage = 'La contraseña es incorrecta';
          break;
        case 'email-already-in-use':
          errorMessage = 'Ya existe una cuenta con este correo electrónico';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Esta operación no está permitida';
          break;
        case 'weak-password':
          errorMessage = 'La contraseña es demasiado débil';
          break;
        case 'network-request-failed':
          errorMessage = 'Problema de conexión. Verifica tu conexión a internet';
          break;
        case 'too-many-requests':
          errorMessage = 'Demasiados intentos fallidos. Intenta más tarde';
          break;
        // --- AÑADIDO PARA GOOGLE ---
        case 'sign-in-cancelled':
          errorMessage = 'Inicio de sesión cancelado';
          break;
        case 'account-exists-with-different-credential':
          errorMessage = 'Ya existe una cuenta con este correo, pero con un método de inicio de sesión diferente';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }
    } else {
      errorMessage = e.toString();
    }
    
    return errorMessage;
  }
  
  // Actualizar datos de usuario
  Future<bool> updateUserData(Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firebaseService.saveUserData(_user!.uid, userData);
      
      // Actualizar datos locales
      if (_userData != null) {
        _userData!.addAll(userData);
      } else {
        _userData = userData;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al actualizar datos: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // --- MÉTODOS AÑADIDOS ---

  Future<void> updateProfilePicture(File imageFile) async {
    if (_user == null) throw Exception('Usuario no autenticado');
    _isLoading = true;
    notifyListeners();
    
    try {
      // Subir imagen
      String fileName = '${const Uuid().v4()}.jpg';
      String path = 'perfiles/${_user!.uid}/$fileName';
      
      final ref = _firebaseService.storage.ref(path);
      final uploadTask = await ref.putFile(imageFile);
      final url = await uploadTask.ref.getDownloadURL();
      
      // Actualizar URL en Firebase Auth
      await _user!.updatePhotoURL(url);
      
      // Actualizar URL en Firestore
      await updateUserData({'photoURL': url});
      
      // Refrescar usuario local
      await _user!.reload();
      _user = _firebaseService.auth.currentUser;
      
    } catch (e) {
      _errorMessage = 'Error al subir imagen: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDisplayName(String newName) async {
    if (_user == null) throw Exception('Usuario no autenticado');
    _isLoading = true;
    notifyListeners();
    
    try {
      // Actualizar en Firebase Auth
      await _user!.updateDisplayName(newName);
      
      // Actualizar en Firestore
      await updateUserData({'displayName': newName});
      
      // Refrescar usuario local
      await _user!.reload();
      _user = _firebaseService.auth.currentUser;
      
    } catch (e) {
      _errorMessage = 'Error al actualizar nombre: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_user == null || _user!.email == null) throw Exception('Usuario no autenticado o sin email');
    _isLoading = true;
    notifyListeners();
    
    try {
      // Re-autenticar al usuario
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      
      await _user!.reauthenticateWithCredential(credential);
      
      // Cambiar contraseña
      await _user!.updatePassword(newPassword);
      
    } catch (e) {
      _errorMessage = _handleAuthError(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount(String password) async {
    if (_user == null || _user!.email == null) throw Exception('Usuario no autenticado o sin email');
    _isLoading = true;
    notifyListeners();
    
    try {
      // Re-autenticar al usuario
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: password,
      );
      
      await _user!.reauthenticateWithCredential(credential);
      
      // Eliminar usuario
      await _user!.delete();
      
      // Limpiar estado (el listener _onAuthStateChanged hará el resto)
      _user = null;
      _userData = null;
      _status = AuthStatus.unauthenticated;
      
    } catch (e) {
      _errorMessage = _handleAuthError(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}