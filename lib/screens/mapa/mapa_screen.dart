// lib/screens/mapa/mapa_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:arbolitos/config/theme.dart';
import 'package:arbolitos/models/arbol_model.dart';
import 'package:arbolitos/providers/arbol_provider.dart';
import 'package:arbolitos/screens/ver_arbol/ver_arbol_screen.dart';
import 'package:arbolitos/widgets/common_widgets.dart';

class MapaScreen extends StatefulWidget {
  final String? arbolSeleccionadoId;
  
  const MapaScreen({
    Key? key,
    this.arbolSeleccionadoId,
  }) : super(key: key);

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Map<String, Marker> _markers = {};
  
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(40.7128, -74.0060), // Nueva York por defecto
    zoom: 12,
  );
  
  bool _isLoading = false;
  bool _locationError = false;
  String _errorMessage = '';
  
  // Para filtrado y búsqueda
  double _radioKm = 10.0; // Radio de búsqueda en km
  Position? _currentPosition;
  Arbol? _arbolSeleccionado;
  List<Arbol> _arbolesCercanos = [];
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
      
      setState(() {
        _currentPosition = position;
        _initialCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14,
        );
      });
      
      // Cargar árboles cercanos
      _loadArbolesCercanos();
      
      // Si hay un árbol seleccionado, mostrarlo
      if (widget.arbolSeleccionadoId != null) {
        _mostrarArbolSeleccionado(widget.arbolSeleccionadoId!);
      }
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
  
  // Cargar árboles cercanos
  Future<void> _loadArbolesCercanos() async {
    if (_currentPosition == null) return;
    
    final arbolProvider = Provider.of<ArbolProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _arbolesCercanos = await arbolProvider.getArbolesCercanos(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _radioKm,
      );
      
      // Agregar marcadores al mapa
      _addMarkers();
    } catch (e) {
      print('Error al cargar árboles cercanos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Mostrar árbol seleccionado
  Future<void> _mostrarArbolSeleccionado(String arbolId) async {
    final arbolProvider = Provider.of<ArbolProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final Arbol? arbol = await arbolProvider.getArbol(arbolId);
      
      if (arbol != null && arbol.esPublico && arbol.ubicacion != null) {
        setState(() {
          _arbolSeleccionado = arbol;
        });
        
        // Mover cámara a la ubicación del árbol
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(arbol.ubicacion!.lat, arbol.ubicacion!.lng),
          16,
        ));
        
        // Mostrar info del árbol seleccionado
        _showArbolInfo(arbol);
      }
    } catch (e) {
      print('Error al cargar árbol seleccionado: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Agregar marcadores al mapa
  void _addMarkers() {
    // Limpiar marcadores existentes
    _markers.clear();
    
    // Agregar marcador de ubicación actual
    if (_currentPosition != null) {
      _markers['currentLocation'] = Marker(
        markerId: const MarkerId('currentLocation'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Tu ubicación'),
      );
    }
    
    // Agregar marcadores para cada árbol cercano
    for (var arbol in _arbolesCercanos) {
      if (arbol.ubicacion != null) {
        _markers[arbol.id!] = Marker(
          markerId: MarkerId(arbol.id!),
          position: LatLng(arbol.ubicacion!.lat, arbol.ubicacion!.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: arbol.nombre,
            snippet: 'Toca para ver detalles',
            onTap: () => _showArbolInfo(arbol),
          ),
          onTap: () => _showArbolInfo(arbol),
        );
      }
    }
    
    setState(() {});
  }
  
  // Mostrar información de un árbol
  void _showArbolInfo(Arbol arbol) {
    setState(() {
      _arbolSeleccionado = arbol;
    });
    
    // Scroll para mostrar detalles del árbol
    // (El panel inferior debería mostrarse automáticamente)
  }
  
  // Buscar árboles cercanos
  Future<void> _buscarArbolesCercanos() async {
    await _loadArbolesCercanos();
    
    // Ajustar cámara para mostrar todos los marcadores
    if (_markers.isNotEmpty && _controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      
      // Si solo está el marcador de ubicación actual, no hacer nada
      if (_markers.length > 1 || (_markers.length == 1 && !_markers.containsKey('currentLocation'))) {
        // Crear bounds que incluya todos los marcadores
        LatLngBounds bounds = _createBoundsFromMarkers();
        
        // Animar cámara para mostrar todos los marcadores
        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      }
    }
  }
  
  // Crear bounds a partir de marcadores
  LatLngBounds _createBoundsFromMarkers() {
    double? minLat;
    double? maxLat;
    double? minLng;
    double? maxLng;
    
    // Encontrar extremos
    _markers.forEach((_, marker) {
      if (minLat == null || marker.position.latitude < minLat!) {
        minLat = marker.position.latitude;
      }
      if (maxLat == null || marker.position.latitude > maxLat!) {
        maxLat = marker.position.latitude;
      }
      if (minLng == null || marker.position.longitude < minLng!) {
        minLng = marker.position.longitude;
      }
      if (maxLng == null || marker.position.longitude > maxLng!) {
        maxLng = marker.position.longitude;
      }
    });
    
    // Crear bounds
    return LatLngBounds(
      southwest: LatLng(minLat! - 0.01, minLng! - 0.01), // Añadir un pequeño padding
      northeast: LatLng(maxLat! + 0.01, maxLng! + 0.01),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Memorial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
            tooltip: 'Actualizar ubicación',
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
            markers: Set<Marker>.of(_markers.values),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          
          // Panel de controles en la parte superior
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Radio de búsqueda',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _radioKm,
                            min: 1,
                            max: 50,
                            divisions: 49,
                            label: '${_radioKm.round()} km',
                            onChanged: (value) {
                              setState(() {
                                _radioKm = value;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          '${_radioKm.round()} km',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _buscarArbolesCercanos,
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Buscar árboles cercanos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Panel de información de árbol seleccionado
          if (_arbolSeleccionado != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Encabezado con nombre y botón de cerrar
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _arbolSeleccionado!.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _arbolSeleccionado = null;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 20,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Información adicional
                      Text(
                        'Por ${_arbolSeleccionado!.usuarioNombre}',
                        style: const TextStyle(
                          color: AppTheme.textColorLight,
                          fontSize: 14,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Fechas
                      Row(
                        children: [
                          if (_arbolSeleccionado!.nacimiento != null) ...[
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppTheme.textColorLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Nacimiento: ${_arbolSeleccionado!.nacimiento}',
                              style: const TextStyle(
                                color: AppTheme.textColorLight,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (_arbolSeleccionado!.fallecimiento != null) ...[
                            const Icon(
                              Icons.brightness_3,
                              size: 16,
                              color: AppTheme.textColorLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Fallecimiento: ${_arbolSeleccionado!.fallecimiento}',
                              style: const TextStyle(
                                color: AppTheme.textColorLight,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Botones de acción
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VerArbolScreen(
                                      arbolId: _arbolSeleccionado!.id!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility, size: 18),
                              label: const Text('Ver detalles'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                side: const BorderSide(color: AppTheme.primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VerArbolScreen(
                                      arbolId: _arbolSeleccionado!.id!,
                                      iniciarAR: true,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.view_in_ar, size: 18),
                              label: const Text('Ver en AR'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
            ),
          
          // Botón de mi ubicación
          Positioned(
            right: 16,
            bottom: _arbolSeleccionado != null ? 160 : 16,
            child: FloatingActionButton(
              onPressed: () async {
                if (_currentPosition != null && _controller.isCompleted) {
                  final GoogleMapController controller = await _controller.future;
                  controller.animateCamera(CameraUpdate.newLatLngZoom(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    16,
                  ));
                }
              },
              mini: true,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: AppTheme.primaryColor),
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