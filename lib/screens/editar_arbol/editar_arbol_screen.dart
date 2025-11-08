// lib/screens/editar_arbol/editar_arbol_screen.dart

import 'dart:io'; // <-- CORREGIDO
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:arbolitos/config/theme.dart';
import 'package:arbolitos/models/arbol_model.dart'; // <-- CORREGIDO
import 'package:arbolitos/providers/auth_provider.dart';
import 'package:arbolitos/providers/arbol_provider.dart';
import 'package:arbolitos/widgets/common_widgets.dart';
import 'package:arbolitos/screens/mapa/mapa_selector.dart'; // <-- CORREGIDO

class EditarArbolScreen extends StatefulWidget {
  final String arbolId;
  
  const EditarArbolScreen({
    Key? key,
    required this.arbolId,
  }) : super(key: key);

  @override
  State<EditarArbolScreen> createState() => _EditarArbolScreenState();
}

class _EditarArbolScreenState extends State<EditarArbolScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cancionController = TextEditingController();
  
  String _modelo = "jabami_anime_tree_v2.glb";
  String _nacimiento = "";
  String _fallecimiento = "";
  List<File> _imagenesNuevas = [];
  List<String> _imagenesActuales = [];
  bool _esPublico = false;
  Ubicacion? _ubicacion;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _mostrarMapa = false;
  
  final ImagePicker _picker = ImagePicker();
  Arbol? _arbolActual;

  // Lista de modelos disponibles
  final List<Map<String, dynamic>> _modelosDisponibles = [
    {
      "value": "jabami_anime_tree_v2.glb",
      "label": "Árbol estilo Anime",
      "description": "Un árbol con estética japonesa moderna",
    },
    {
      "value": "low_poly_purple_flowers.glb",
      "label": "Árbol con flores púrpura",
      "description": "Delicadas flores en tonos violeta",
    },
    {
      "value": "tree_elm.glb",
      "label": "Olmo",
      "description": "Árbol clásico de gran elegancia",
    },
    {
      "value": "ficus_bonsai.glb",
      "label": "Ficus Bonsai",
      "description": "Pequeño pero lleno de significado",
    },
    {
      "value": "flowerpot.glb",
      "label": "Maceta con flor",
      "description": "Una planta en maceta decorativa",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadArbolData();
  }
  
  // Cargar datos del árbol
  Future<void> _loadArbolData() async {
    try {
      final arbolProvider = Provider.of<ArbolProvider>(context, listen: false);
      _arbolActual = await arbolProvider.getArbol(widget.arbolId);
      
      if (_arbolActual == null) {
        throw 'Árbol no encontrado';
      }
      
      // Llenar formulario
      setState(() {
        _nombreController.text = _arbolActual!.nombre;
        _modelo = _arbolActual!.modelo;
        _nacimiento = _arbolActual!.nacimiento ?? "";
        _fallecimiento = _arbolActual!.fallecimiento ?? "";
        _cancionController.text = _arbolActual!.cancion ?? "";
        _imagenesActuales = List<String>.from(_arbolActual!.imagenes);
        _esPublico = _arbolActual!.esPublico;
        _ubicacion = _arbolActual!.ubicacion;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos del árbol: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cancionController.dispose();
    super.dispose();
  }

  // Seleccionar imágenes de la galería
  Future<void> _selectImages() async {
    try {
      final List<XFile> selectedImages = await _picker.pickMultiImage();
      
      if (selectedImages.isNotEmpty) {
        // Convertir a File y agregar a la lista
        final List<File> imageFiles = selectedImages.map((xFile) => File(xFile.path)).toList();
        
        // Verificar límite de 5 imágenes
        final int totalImagenes = _imagenesActuales.length + _imagenesNuevas.length + imageFiles.length;
        
        if (totalImagenes > 5) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Puedes tener máximo 5 imágenes en total'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          
          final int espacioDisponible = 5 - (_imagenesActuales.length + _imagenesNuevas.length);
          if (espacioDisponible > 0) {
            setState(() {
              _imagenesNuevas.addAll(imageFiles.take(espacioDisponible));
            });
          }
        } else {
          setState(() {
            _imagenesNuevas.addAll(imageFiles);
          });
        }
      }
    } catch (e) {
      print('Error al seleccionar imágenes: $e');
    }
  }
  
  // Eliminar imagen nueva (local)
  void _removeNewImage(int index) {
    setState(() {
      _imagenesNuevas.removeAt(index);
    });
  }
  
  // Eliminar imagen existente (de la URL)
  void _removeExistingImage(int index) {
    setState(() {
      _imagenesActuales.removeAt(index);
      // Nota: La eliminación física del storage se maneja en el provider al guardar
    });
  }
  
  // Obtener ubicación actual
  Future<void> _getCurrentLocation() async {
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
      
      // Obtener dirección a partir de coordenadas
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      String direccion = 'Ubicación actual';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        direccion = '${place.street}, ${place.locality}, ${place.country}';
      }
      
      // Crear objeto Ubicacion
      setState(() {
        _ubicacion = Ubicacion(
          lat: position.latitude,
          lng: position.longitude,
          direccion: direccion,
          geohash: Ubicacion.generarGeohash(position.latitude, position.longitude),
        );
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  // Guardar cambios
  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_esPublico && _ubicacion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Para hacer el árbol público, debes seleccionar una ubicación.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final arbolProvider = Provider.of<ArbolProvider>(context, listen: false);
      
      if (authProvider.user == null) {
        throw 'Usuario no autenticado';
      }
      
      // Actualizar el árbol
      final bool success = await arbolProvider.updateArbol(
        arbolId: widget.arbolId,
        nombre: _nombreController.text.trim(),
        modelo: _modelo,
        nacimiento: _nacimiento.isNotEmpty ? _nacimiento : null,
        fallecimiento: _fallecimiento.isNotEmpty ? _fallecimiento : null,
        cancion: _cancionController.text.isNotEmpty ? _cancionController.text.trim() : null,
        nuevasImagenes: _imagenesNuevas,
        imagenesActuales: _imagenesActuales,
        esPublico: _esPublico,
        ubicacion: _esPublico ? _ubicacion : null,
        usuarioNombre: authProvider.user!.displayName ?? authProvider.user!.email?.split('@')[0] ?? 'Usuario Anónimo',
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Árbol actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Árbol'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _isSaving
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryColor),
                      SizedBox(height: 16),
                      Text('Guardando cambios...'),
                    ],
                  ),
                )
              : _mostrarMapa
                  ? MapaSelector(
                      onSeleccionarUbicacion: (ubicacion) {
                        setState(() {
                          _ubicacion = ubicacion;
                          _mostrarMapa = false;
                        });
                      },
                      ubicacionInicial: _ubicacion,
                      onCancelar: () {
                        setState(() {
                          _mostrarMapa = false;
                        });
                      },
                    )
                  : _buildForm(),
    );
  }
  
  // Construir formulario
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nombre del árbol
            CustomTextField(
              label: 'Nombre del árbol *',
              hint: 'Ej: En memoria de María García',
              controller: _nombreController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Sección de privacidad y ubicación
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColorLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.public, size: 20, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Privacidad y Ubicación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Checkbox para hacer público
                  Row(
                    children: [
                      Checkbox(
                        value: _esPublico,
                        onChanged: (value) {
                          setState(() {
                            _esPublico = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                      const Expanded(
                        child: Text(
                          'Hacer este árbol público',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.only(left: 40),
                    child: Text(
                      'Los árboles públicos aparecen en el mapa memorial y pueden ser visitados por cualquier persona',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textColorLight,
                      ),
                    ),
                  ),
                  
                  // Ubicación (si es público)
                  if (_esPublico) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Ubicación del árbol *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Mostrar ubicación seleccionada
                    if (_ubicacion != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColorLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ubicación seleccionada',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _ubicacion!.direccion,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textColorLight,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  _ubicacion = null;
                                });
                              },
                              color: AppTheme.textColorLight,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                    
                    // Botones para seleccionar ubicación
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.my_location, size: 18),
                            label: const Text('Mi ubicación'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(color: AppTheme.primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _mostrarMapa = true;
                              });
                            },
                            icon: const Icon(Icons.map, size: 18),
                            label: const Text('Elegir en mapa'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(color: AppTheme.primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Selección de modelo 3D
            const Text(
              'Selecciona un modelo 3D *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Grid de modelos
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _modelosDisponibles.length,
              itemBuilder: (context, index) {
                final modelo = _modelosDisponibles[index];
                final bool isSelected = _modelo == modelo['value'];
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _modelo = modelo['value'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected ? AppTheme.primaryColorLight.withOpacity(0.3) : Colors.white,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          modelo['label'],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          modelo['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textColorLight,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Vista previa del modelo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.view_in_ar, size: 60, color: Colors.grey.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text(
                      'Vista previa del modelo seleccionado',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textColorLight),
                    ),
                  ],
                ),
              ),
              // TODO: Implementar visualizador de modelo 3D
            ),
            
            const SizedBox(height: 24),
            
            // Fechas
            Row(
              children: [
                // Fecha de nacimiento
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha de nacimiento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _nacimiento.isNotEmpty ? DateTime.tryParse(_nacimiento) : DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          
                          if (picked != null) {
                            setState(() {
                              _nacimiento = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20, color: AppTheme.textColorLight),
                              const SizedBox(width: 8),
                              Text(
                                _nacimiento.isNotEmpty ? _nacimiento : 'Seleccionar',
                                style: TextStyle(
                                  color: _nacimiento.isNotEmpty ? AppTheme.textColor : AppTheme.textColorLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Fecha de fallecimiento
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha de fallecimiento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _fallecimiento.isNotEmpty ? DateTime.tryParse(_fallecimiento) : DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          
                          if (picked != null) {
                            setState(() {
                              _fallecimiento = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20, color: AppTheme.textColorLight),
                              const SizedBox(width: 8),
                              Text(
                                _fallecimiento.isNotEmpty ? _fallecimiento : 'Seleccionar',
                                style: TextStyle(
                                  color: _fallecimiento.isNotEmpty ? AppTheme.textColor : AppTheme.textColorLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Campo para enlace de YouTube
            CustomTextField(
              label: 'Enlace de canción (YouTube)',
              hint: 'https://www.youtube.com/watch?v=...',
              controller: _cancionController,
              keyboardType: TextInputType.url,
            ),
            
            const SizedBox(height: 24),
            
            // Selector de imágenes
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Imágenes (máximo 5)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Previsualización de imágenes existentes
                if (_imagenesActuales.isNotEmpty) ...[
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagenesActuales.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: _imagenesActuales[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Center(child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.error),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeExistingImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Previsualización de imágenes nuevas
                if (_imagenesNuevas.isNotEmpty) ...[
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagenesNuevas.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imagenesNuevas[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeNewImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Botón para añadir más imágenes
                if (_imagenesActuales.length + _imagenesNuevas.length < 5)
                  InkWell(
                    onTap: _selectImages,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.borderColor,
                          style: BorderStyle.solid, // <-- CORREGIDO
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 36, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            const Text(
                              'Añadir más imágenes',
                              style: TextStyle(color: AppTheme.textColorLight),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    text: 'Guardar Cambios',
                    onPressed: _guardarCambios,
                    isLoading: _isSaving,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}