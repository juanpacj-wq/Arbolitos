// lib/screens/mapa/mapa_selector.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:arbolitos/config/theme.dart';
import 'package:arbolitos/models/arbol_model.dart';
import 'package:arbolitos/widgets/common_widgets.dart';

class MapaSelector extends StatefulWidget {
  final Function(Ubicacion) onSeleccionarUbicacion;
  final VoidCallback onCancelar;
  final Ubicacion? ubicacionInicial;
  
  const MapaSelector({
    Key? key,
    required this.onSeleccionarUbicacion,
    required this.onCancelar,
    this.ubicacionInicial,
  }) : super(key: key);

  @override
  State<MapaSelector> createState() => _MapaSelectorState();
}

class _MapaSelectorState extends State<MapaSelector> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(40.7128, -74.0060), // Nueva York por defecto
    zoom: 14,
  );
  
  Marker? _marker;
  bool _isLoading = false;
  bool _locationError = false;
  String _errorMessage = '';
  Ubicacion? _selectedLocation;
  
  @override
  void initState() {
    super.initState();
    
    // Si hay ubicación inicial, usarla
    if (widget.ubicacionInicial != null) {
      _initialCameraPosition = CameraPosition(
        target: LatLng(
          widget.ubicacionInicial!.lat,
          widget.ubicacionInicial!.lng,
        ),
        zoom: 14,
      );
      
      _selectedLocation = widget.ubicacionInicial;
      _marker = Marker(
        markerId: const MarkerId('selected_location'),
        position: LatLng(
          widget.ubicacionInicial!.lat,
          widget.ubicacionInicial!.lng,
        ),
        draggable: true,
        onDragEnd: _onMarkerDragEnd,
      );
    } else {
      _getCurrentLocation();
    }
  }

  // Obtener ubicación actual
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _locationError = false;
      _errorMessage = '';
    });
    
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permiso de ubicación denegado';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Permiso de ubicación denegado permanentemente. Debes habilitarlo en la configuración.';
      }
      
      // Obtener ubicación
      final Position position = await Geolocator.getCurrentPosition();
      
      // Actualizar cámara y marcador
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        14,
      ));
      
      // Obtener dirección
      _getAddressFromLatLng(position.latitude, position.longitude);
      
      setState(() {
        _marker = Marker(
          markerId: const MarkerId('selected_location'),
          position: LatLng(position.latitude, position.longitude),
          draggable: true,
          onDragEnd: _onMarkerDragEnd,
        );
      });
    } catch (e) {
      setState(() {
        _locationError = true;
        _errorMessage = 'Error al obtener ubicación: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Cuando el marcador se arrastra
  void _onMarkerDragEnd(LatLng position) {
    setState(() {
      _marker = Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
        draggable: true,
        onDragEnd: _onMarkerDragEnd,
      );
    });
    
    // Obtener dirección para la nueva posición
    _getAddressFromLatLng(position.latitude, position.longitude);
  }
  
  // Cuando se hace tap en el mapa
  void _onMapTap(LatLng position) {
    setState(() {
      _marker = Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
        draggable: true,
        onDragEnd: _onMarkerDragEnd,
      );
    });
    
    // Obtener dirección para la nueva posición
    _getAddressFromLatLng(position.latitude, position.longitude);
  }
  
  // Buscar ubicación por texto
  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<Location> locations = await locationFromAddress(_searchController.text);
      
      if (locations.isNotEmpty) {
        Location location = locations.first;
        
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          14,
        ));
        
        setState(() {
          _marker = Marker(
            markerId: const MarkerId('selected_location'),
            position: LatLng(location.latitude, location.longitude),
            draggable: true,
            onDragEnd: _onMarkerDragEnd,
          );
        });
        
        // Obtener dirección completa
        _getAddressFromLatLng(location.latitude, location.longitude);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se encontró la ubicación: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Obtener dirección a partir de coordenadas
  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String direccion = '';
        
        if (place.street != null && place.street!.isNotEmpty) {
          direccion += place.street!;
        }
        
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (direccion.isNotEmpty) direccion += ', ';
          direccion += place.locality!;
        }
        
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (direccion.isNotEmpty) direccion += ', ';
          direccion += place.administrativeArea!;
        }
        
        if (place.country != null && place.country!.isNotEmpty) {
          if (direccion.isNotEmpty) direccion += ', ';
          direccion += place.country!;
        }
        
        // Si no se pudo obtener una dirección
        if (direccion.isEmpty) {
          direccion = 'Ubicación seleccionada';
        }
        
        setState(() {
          _selectedLocation = Ubicacion(
            lat: lat,
            lng: lng,
            direccion: direccion,
            geohash: Ubicacion.generarGeohash(lat, lng),
          );
        });
      }
    } catch (e) {
      print('Error al obtener dirección: $e');
      
      setState(() {
        _selectedLocation = Ubicacion(
          lat: lat,
          lng: lng,
          direccion: 'Ubicación seleccionada',
          geohash: Ubicacion.generarGeohash(lat, lng),
        );
      });
    }
  }
  
  // Confirmar selección
  void _confirmarSeleccion() {
    if (_selectedLocation != null) {
      widget.onSeleccionarUbicacion(_selectedLocation!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        actions: [
          // Botón de mi ubicación
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Mi ubicación',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _marker != null ? {_marker!} : {},
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onTap: _onMapTap,
          ),
          
          // Barra de búsqueda
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppTheme.textColorLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Buscar ubicación',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: AppTheme.textColorLight),
                        ),
                        onSubmitted: (_) => _searchLocation(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.textColorLight),
                      onPressed: () {
                        _searchController.clear();
                      },
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Panel inferior con información de ubicación seleccionada
          if (_selectedLocation != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ubicación seleccionada',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedLocation!.direccion,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      'Coordenadas: ${_selectedLocation!.lat.toStringAsFixed(6)}, ${_selectedLocation!.lng.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textColorLight,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onCancelar,
                            child: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _confirmarSeleccion,
                            child: const Text('Confirmar ubicación'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          // Indicador de carga
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            ),
          
          // Mensaje de error
          if (_locationError)
            Positioned(
              top: 70,
              left: 16,
              right: 16,
              child: ErrorMessage(
                message: _errorMessage,
                onRetry: _getCurrentLocation,
              ),
            ),
        ],
      ),
    );
  }
}