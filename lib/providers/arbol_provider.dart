// lib/providers/arbol_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:arbolitos/services/firebase_service.dart';
import 'package:arbolitos/models/arbol_model.dart';

class ArbolProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Arbol> _arboles = [];
  List<Arbol> _arbolesPublicos = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Arbol? _selectedArbol;
  
  // Getters
  List<Arbol> get arboles => _arboles;
  List<Arbol> get arbolesPublicos => _arbolesPublicos;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Arbol? get selectedArbol => _selectedArbol;
  
  // Obtener árboles del usuario
  Future<void> fetchArbolesUsuario(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      final snapshot = await _firestore
          .collection('arboles')
          .where('uid', isEqualTo: userId)
          .orderBy('creado', descending: true)
          .get();
      
      _arboles = snapshot.docs.map((doc) => Arbol.fromFirestore(doc)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cargar árboles: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Obtener árboles públicos
  Future<void> fetchArbolesPublicos() async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      final snapshot = await _firestore
          .collection('arboles')
          .where('esPublico', isEqualTo: true)
          .orderBy('creado', descending: true)
          .get();
      
      _arbolesPublicos = snapshot.docs.map((doc) => Arbol.fromFirestore(doc)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cargar árboles públicos: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Obtener un árbol específico
  Future<Arbol?> getArbol(String arbolId) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      final docSnapshot = await _firestore
          .collection('arboles')
          .doc(arbolId)
          .get();
      
      if (docSnapshot.exists) {
        _selectedArbol = Arbol.fromFirestore(docSnapshot);
        
        _isLoading = false;
        notifyListeners();
        return _selectedArbol;
      } else {
        _isLoading = false;
        _errorMessage = 'Árbol no encontrado';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al obtener árbol: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
  
  // Crear un nuevo árbol
  Future<Arbol?> createArbol({
    required String uid,
    required String nombre,
    required String modelo,
    String? nacimiento,
    String? fallecimiento,
    String? cancion,
    required List<File> imagenes,
    required bool esPublico,
    Ubicacion? ubicacion,
    required String usuarioNombre,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      // Subir imágenes a Storage
      List<String> imagenesUrls = [];
      for (var imagen in imagenes) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.jpg';
        String path = 'arboles/$uid/$fileName';
        
        try {
          final ref = _firebaseService.storage.ref(path);
          final uploadTask = await ref.putFile(imagen);
          final url = await uploadTask.ref.getDownloadURL();
          imagenesUrls.add(url);
        } catch (e) {
          print('Error al subir imagen: $e');
        }
      }
      
      // Crear documento en Firestore
      final datosArbol = {
        'uid': uid,
        'nombre': nombre,
        'modelo': modelo,
        'nacimiento': nacimiento,
        'fallecimiento': fallecimiento,
        'cancion': cancion,
        'imagenes': imagenesUrls,
        'creado': FieldValue.serverTimestamp(),
        'esPublico': esPublico,
        'usuarioNombre': usuarioNombre,
      };
      
      // Si hay ubicación, agregarla
      if (esPublico && ubicacion != null) {
        datosArbol['ubicacion'] = {
          'lat': ubicacion.lat,
          'lng': ubicacion.lng,
          'direccion': ubicacion.direccion,
          'geohash': ubicacion.geohash,
        };
      }
      
      // Guardar en Firestore
      DocumentReference docRef = await _firestore.collection('arboles').add(datosArbol);
      
      // Obtener el documento recién creado
      DocumentSnapshot newDoc = await docRef.get();
      final arbol = Arbol.fromFirestore(newDoc);
      
      // Añadir a la lista local
      _arboles.insert(0, arbol);
      
      if (esPublico) {
        _arbolesPublicos.insert(0, arbol);
      }
      
      _isLoading = false;
      notifyListeners();
      
      return arbol;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al crear árbol: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
  
  // Actualizar árbol existente
  Future<bool> updateArbol({
    required String arbolId,
    required String nombre,
    required String modelo,
    String? nacimiento,
    String? fallecimiento,
    String? cancion,
    List<File>? nuevasImagenes,
    List<String>? imagenesActuales,
    required bool esPublico,
    Ubicacion? ubicacion,
    required String usuarioNombre,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      // Obtener referencia del documento
      final docRef = _firestore.collection('arboles').doc(arbolId);
      
      // Obtener documento actual
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        _isLoading = false;
        _errorMessage = 'Árbol no encontrado';
        notifyListeners();
        return false;
      }
      
      final currentData = docSnapshot.data() as Map<String, dynamic>;
      final String uid = currentData['uid'] as String;
      
      // Lista de URLs de imágenes actuales
      List<String> imagenesUrls = [];
      
      // Mantener imágenes actuales si se proporcionan
      if (imagenesActuales != null) {
        imagenesUrls.addAll(imagenesActuales);
      }
      
      // Subir nuevas imágenes si las hay
      if (nuevasImagenes != null && nuevasImagenes.isNotEmpty) {
        for (var imagen in nuevasImagenes) {
          String fileName = '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.jpg';
          String path = 'arboles/$uid/$fileName';
          
          try {
            final ref = _firebaseService.storage.ref(path);
            final uploadTask = await ref.putFile(imagen);
            final url = await uploadTask.ref.getDownloadURL();
            imagenesUrls.add(url);
          } catch (e) {
            print('Error al subir nueva imagen: $e');
          }
        }
      }
      
      // Crear mapa con datos actualizados
      final datosActualizados = {
        'nombre': nombre,
        'modelo': modelo,
        'nacimiento': nacimiento,
        'fallecimiento': fallecimiento,
        'cancion': cancion,
        'imagenes': imagenesUrls,
        'esPublico': esPublico,
        'usuarioNombre': usuarioNombre,
      };
      
      // Si hay ubicación y es público, agregarla
      if (esPublico && ubicacion != null) {
        datosActualizados['ubicacion'] = {
          'lat': ubicacion.lat,
          'lng': ubicacion.lng,
          'direccion': ubicacion.direccion,
          'geohash': ubicacion.geohash,
        };
      } else {
        // Si no es público, eliminar ubicación si existe
        datosActualizados['ubicacion'] = null;
      }
      
      // Actualizar documento
      await docRef.update(datosActualizados);
      
      // Actualizar listas locales
      await getArbol(arbolId);
      
      // Actualizar listas
      int index = _arboles.indexWhere((arbol) => arbol.id == arbolId);
      if (index != -1) {
        _arboles[index] = _selectedArbol!;
      }
      
      int indexPublico = _arbolesPublicos.indexWhere((arbol) => arbol.id == arbolId);
      if (esPublico) {
        if (indexPublico != -1) {
          _arbolesPublicos[indexPublico] = _selectedArbol!;
        } else {
          _arbolesPublicos.insert(0, _selectedArbol!);
        }
      } else if (indexPublico != -1) {
        _arbolesPublicos.removeAt(indexPublico);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al actualizar árbol: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Eliminar árbol
  Future<bool> deleteArbol(String arbolId) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      // Obtener documento
      final docSnapshot = await _firestore.collection('arboles').doc(arbolId).get();
      
      if (!docSnapshot.exists) {
        _isLoading = false;
        _errorMessage = 'Árbol no encontrado';
        notifyListeners();
        return false;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      // Eliminar imágenes de Storage
      if (data['imagenes'] != null && data['imagenes'] is List) {
        List<dynamic> imagenes = data['imagenes'];
        for (String url in List<String>.from(imagenes)) {
          try {
            // Extraer path de la URL
            final ref = FirebaseStorage.instance.refFromURL(url);
            await ref.delete();
          } catch (e) {
            print('Error al eliminar imagen: $e');
          }
        }
      }
      
      // Eliminar documento
      await _firestore.collection('arboles').doc(arbolId).delete();
      
      // Actualizar listas locales
      _arboles.removeWhere((arbol) => arbol.id == arbolId);
      _arbolesPublicos.removeWhere((arbol) => arbol.id == arbolId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al eliminar árbol: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Eliminar una imagen específica
  Future<bool> deleteImage(String arbolId, String imageUrl) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      // Obtener documento
      final docRef = _firestore.collection('arboles').doc(arbolId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        _isLoading = false;
        _errorMessage = 'Árbol no encontrado';
        notifyListeners();
        return false;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      // Obtener lista actual de imágenes
      List<dynamic> currentImages = data['imagenes'] ?? [];
      List<String> updatedImages = List<String>.from(currentImages);
      
      // Eliminar imagen de la lista
      updatedImages.remove(imageUrl);
      
      // Actualizar documento
      await docRef.update({'imagenes': updatedImages});
      
      // Eliminar archivo de Storage
      try {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();
      } catch (e) {
        print('Error al eliminar imagen de Storage: $e');
      }
      
      // Actualizar modelo local
      await getArbol(arbolId);
      
      // Actualizar listas
      int index = _arboles.indexWhere((arbol) => arbol.id == arbolId);
      if (index != -1) {
        _arboles[index] = _selectedArbol!;
      }
      
      int indexPublico = _arbolesPublicos.indexWhere((arbol) => arbol.id == arbolId);
      if (indexPublico != -1) {
        _arbolesPublicos[indexPublico] = _selectedArbol!;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al eliminar imagen: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Obtener árboles cercanos (basado en geohash)
  Future<List<Arbol>> getArbolesCercanos(double lat, double lng, double radioKm) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      // Obtener todos los árboles públicos (en una aplicación real usaríamos GeoFirestore)
      final snapshot = await _firestore
          .collection('arboles')
          .where('esPublico', isEqualTo: true)
          .get();
      
      final List<Arbol> arbolesCercanos = [];
      
      // Filtrar manualmente por distancia
      for (var doc in snapshot.docs) {
        final arbol = Arbol.fromFirestore(doc);
        
        if (arbol.ubicacion != null) {
          // Calcular distancia usando fórmula Haversine
          final double distancia = _calcularDistancia(
            lat, 
            lng, 
            arbol.ubicacion!.lat, 
            arbol.ubicacion!.lng
          );
          
          // Añadir si está dentro del radio especificado
          if (distancia <= radioKm) {
            arbolesCercanos.add(arbol);
          }
        }
      }
      
      _isLoading = false;
      notifyListeners();
      
      return arbolesCercanos;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al buscar árboles cercanos: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }
  
  // Calcular distancia entre dos coordenadas (fórmula Haversine)
  double _calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radio de la Tierra en km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
      sin(dLon / 2) * sin(dLon / 2);
      
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;
    
    return distance;
  }
  
  // Convertir grados a radianes
  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
  
  // Funciones matemáticas
  double sin(double x) => math.sin(x);
  double cos(double x) => math.cos(x);
  double sqrt(double x) => math.sqrt(x);
  double atan2(double y, double x) => math.atan2(y, x);
}

// Importamos dart:math para funciones matemáticas
import 'dart:math' as math;