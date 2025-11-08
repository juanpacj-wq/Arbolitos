// lib/models/arbol_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Arbol {
  final String? id;
  final String uid; // ID del usuario propietario
  final String nombre;
  final String modelo;
  final String? nacimiento;
  final String? fallecimiento;
  final String? cancion;
  final List<String> imagenes;
  final DateTime creado;
  final bool esPublico;
  final Ubicacion? ubicacion;
  final String usuarioNombre;
  
  Arbol({
    this.id,
    required this.uid,
    required this.nombre,
    required this.modelo,
    this.nacimiento,
    this.fallecimiento,
    this.cancion,
    required this.imagenes,
    required this.creado,
    required this.esPublico,
    this.ubicacion,
    required this.usuarioNombre,
  });
  
  // Factory constructor from Firestore document
  factory Arbol.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Handle ubicacion data
    Ubicacion? ubicacion;
    if (data['ubicacion'] != null) {
      ubicacion = Ubicacion(
        lat: data['ubicacion']['lat'],
        lng: data['ubicacion']['lng'],
        direccion: data['ubicacion']['direccion'] ?? '',
        geohash: data['ubicacion']['geohash'] ?? '',
      );
    }
    
    // Handle imagenes data
    List<String> imagenes = [];
    if (data['imagenes'] != null) {
      imagenes = List<String>.from(data['imagenes']);
    }
    
    return Arbol(
      id: doc.id,
      uid: data['uid'] ?? '',
      nombre: data['nombre'] ?? '',
      modelo: data['modelo'] ?? 'jabami_anime_tree_v2.glb',
      nacimiento: data['nacimiento'],
      fallecimiento: data['fallecimiento'],
      cancion: data['cancion'],
      imagenes: imagenes,
      creado: (data['creado'] as Timestamp).toDate(),
      esPublico: data['esPublico'] ?? false,
      ubicacion: ubicacion,
      usuarioNombre: data['usuarioNombre'] ?? 'Usuario Anónimo',
    );
  }
  
  // Convert model to Map for Firestore
  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> data = {
      'uid': uid,
      'nombre': nombre,
      'modelo': modelo,
      'nacimiento': nacimiento,
      'fallecimiento': fallecimiento,
      'cancion': cancion,
      'imagenes': imagenes,
      'creado': Timestamp.fromDate(creado),
      'esPublico': esPublico,
      'usuarioNombre': usuarioNombre,
    };
    
    // Add ubicacion if available
    if (ubicacion != null) {
      data['ubicacion'] = {
        'lat': ubicacion!.lat,
        'lng': ubicacion!.lng,
        'direccion': ubicacion!.direccion,
        'geohash': ubicacion!.geohash,
      };
    }
    
    return data;
  }
}

class Ubicacion {
  final double lat;
  final double lng;
  final String direccion;
  final String geohash;
  
  Ubicacion({
    required this.lat,
    required this.lng,
    required this.direccion,
    required this.geohash,
  });
  
  // Generar geohash simple para Firebase
  static String generarGeohash(double lat, double lng) {
    final int precision = 5;
    final String latStr = lat.toStringAsFixed(precision);
    final String lngStr = lng.toStringAsFixed(precision);
    return '$latStr,$lngStr';
  }
}