// lib/screens/ver_arbol/ar_view_screen.dart

import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:arbolitos/config/theme.dart';
import 'package:arbolitos/models/arbol_model.dart';
import 'package:vector_math/vector_math_64.dart';

class ARViewScreen extends StatefulWidget {
  final Arbol arbol;
  
  const ARViewScreen({
    Key? key,
    required this.arbol,
  }) : super(key: key);

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;
  
  ARNode? _modelNode;
  String? _error;
  bool _isPlacing = true;
  bool _isInitialized = false;
  bool _isModelLoading = false;

  @override
  void dispose() {
    arSessionManager.dispose();
    super.dispose();
  }
  
  // Inicializar sesión de AR
  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;
    
    arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
    ).then((_) {
      setState(() {
        _isInitialized = true;
      });
      arSessionManager.onPlaneOrPointTap = _onPlaneOrPointTapped;
      _loadInstructions();
    }).catchError((error) {
      setState(() {
        _error = 'Error al inicializar AR: $error';
      });
    });
  }
  
  // Mostrar instrucciones iniciales
  void _loadInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Instrucciones'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('1. Apunta tu cámara a una superficie plana (suelo, mesa, etc.)'),
            SizedBox(height: 8),
            Text('2. Cuando aparezca un plano, toca en la pantalla para colocar el árbol'),
            SizedBox(height: 8),
            Text('3. Usa los gestos para ajustar el tamaño y posición'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
  
  // Cuando se toca un plano o punto en la realidad aumentada
  void _onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) {
    if (!_isPlacing || hitTestResults.isEmpty) return;
    
    // Solo permitir colocar el modelo una vez
    setState(() {
      _isPlacing = false;
      _isModelLoading = true;
    });
    
    // Obtener el primer resultado de hit test
    final hit = hitTestResults.first;
    
    // Configurar el modelo 3D según el tipo seleccionado
    final String modelUrl = _getModelUrl(widget.arbol.modelo);
    
    // Crear un nodo en la posición donde se tocó
    final ARNode node = ARNode(
      type: NodeType.webGLB,
      uri: modelUrl,
      scale: Vector3(0.5, 0.5, 0.5),
      position: hit.worldTransform.getTranslation(),
      rotation: Vector4(1.0, 0.0, 0.0, 0.0),
    );
    
    // Añadir el nodo a la escena
    arObjectManager.addNode(node).then((value) {
      setState(() {
        _modelNode = node;
        _isModelLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _error = 'Error al cargar el modelo: $error';
        _isPlacing = true;
        _isModelLoading = false;
      });
    });
  }
  
  // Reiniciar colocación del modelo
  void _resetPlacement() {
    if (_modelNode != null) {
      arObjectManager.removeNode(_modelNode!);
      _modelNode = null;
    }
    
    setState(() {
      _isPlacing = true;
    });
  }
  
  // Obtener URL del modelo según el tipo
  String _getModelUrl(String modeloId) {
    // En una aplicación real, estos modelos estarían alojados en un servidor o en Firebase Storage
    final baseUrl = 'https://firebasestorage.googleapis.com/v0/b/memorialapp-b1ccf.firebasestorage.app/o/modelos_3d%2F${Uri.encodeComponent(modeloId)}?alt=media';
    return baseUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiencia AR'),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Vista de AR
          ARView(
            onARViewCreated: _onARViewCreated,
          ),
          
          // Mensajes de estado
          if (_error != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Error',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(100, 36),
                      ),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              ),
            ),
          
          // Indicador de carga de modelo
          if (_isModelLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Cargando modelo 3D...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          
          // Estado de inicialización
          if (!_isInitialized)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Inicializando AR...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Apunta tu cámara a una superficie plana',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          
          // Mensaje de instrucciones mientras se coloca
          if (_isInitialized && _isPlacing && !_isModelLoading)
            Positioned(
              bottom: 120,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Toca en una superficie plana para colocar el árbol',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          
          // Botones de acción
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón para reiniciar colocación
                if (!_isPlacing && _modelNode != null)
                  FloatingActionButton(
                    onPressed: _resetPlacement,
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    child: const Icon(Icons.restart_alt),
                    heroTag: 'reset',
                  ),
                
                const SizedBox(width: 16),
                
                // Botón para tomar captura
                FloatingActionButton(
                  onPressed: () {
                    // TODO: Implementar captura de pantalla
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Próximamente: Captura de pantalla'),
                      ),
                    );
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  child: const Icon(Icons.camera_alt),
                  heroTag: 'camera',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}