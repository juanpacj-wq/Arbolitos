// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arbolitos/services/firebase_service.dart';

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
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  
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
}