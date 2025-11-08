// lib/models/arbol_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geohash_plus/geohash_plus.dart'; // <-- Import (está correcto)

class Arbol {
  final String? id;
  final String uid; // ID del usuario propietario
  final String nombre;
  final String modelo; // Sigue siendo solo el nombre del archivo, ej: tree_elm.glb
  final String? nacimiento;
  final String? fallecimiento;
  final String? cancion;
  final List<String> imagenes;
  final DateTime creado;
  final bool esPublico;
  final Ubicacion? ubicacion;
  final String usuarioNombre;
  
  // --- GETTER AÑADIDO (Sin cambios, esto está bien) ---
  String get modeloUrl {
    const String bucket = "memorialapp-b1ccf.firebasestorage.app";
    const String folder = "modelos_3d";
    final String encodedModelo = Uri.encodeComponent(modelo);
    return "https://firebasestorage.googleapis.com/v0/b/$bucket/o/$folder%2F$encodedModelo?alt=media";
  }
  // -----------------------
  
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
  
  // Factory constructor from Firestore document (Sin cambios)
  factory Arbol.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    Ubicacion? ubicacion;
    if (data['ubicacion'] != null) {
      ubicacion = Ubicacion(
        lat: data['ubicacion']['lat'],
        lng: data['ubicacion']['lng'],
        direccion: data['ubicacion']['direccion'] ?? '',
        geohash: data['ubicacion']['geohash'] ?? '',
      );
    }
    
    List<String> imagenes = [];
    if (data['imagenes'] != null) {
      imagenes = List<String>.from(data['imagenes']);
    }
    
    return Arbol(
      id: doc.id,
      uid: data['uid'] ?? '',
      nombre: data['nombre'] ?? '',
      modelo: data['modelo'] ?? 'tree_elm.glb', 
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
  
  // Convert model to Map for Firestore (Sin cambios)
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
    
    if (ubicacion != null) {
      data['ubicacion'] = {
        'lat': ubicacion!.lat,
        'lng': ubicacion!.lng,
        'direccion': ubicacion!.direccion,
        'geohash': Ubicacion.generarGeohash(ubicacion!.lat, ubicacion!.lng),
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
  
  // CORREGIDO: Esta es la sintaxis correcta.
  static String generarGeohash(double lat, double lng) {
    // Usamos una precisión de 7 caracteres (aprox 150m de precisión)
    return GeoHash.encode(lat, lng, precision: 7).hash;
  }
}