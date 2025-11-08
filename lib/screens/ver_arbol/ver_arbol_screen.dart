// lib/screens/ver_arbol/ver_arbol_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arbolitos/config/theme.dart';
import 'package:arbolitos/models/arbol_model.dart';
import 'package:arbolitos/providers/arbol_provider.dart';
import 'package:arbolitos/widgets/common_widgets.dart';
import 'package:arbolitos/screens/ver_arbol/ar_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VerArbolScreen extends StatefulWidget {
  final String arbolId;
  final bool iniciarAR;
  
  const VerArbolScreen({
    Key? key,
    required this.arbolId,
    this.iniciarAR = false,
  }) : super(key: key);

  @override
  State<VerArbolScreen> createState() => _VerArbolScreenState();
}

class _VerArbolScreenState extends State<VerArbolScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Arbol? _arbol;
  int _currentImageIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadArbol();
  }
  
  // Cargar datos del árbol
  Future<void> _loadArbol() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    final arbolProvider = Provider.of<ArbolProvider>(context, listen: false);
    
    try {
      _arbol = await arbolProvider.getArbol(widget.arbolId);
      
      // Si no se encuentra el árbol
      if (_arbol == null) {
        setState(() {
          _errorMessage = 'No se encontró el árbol solicitado.';
        });
        return;
      }
      
      // Si se solicitó iniciar AR automáticamente
      if (widget.iniciarAR && mounted) {
        // Dar tiempo a que se cargue la pantalla antes de lanzar AR
        Future.delayed(const Duration(milliseconds: 500), () {
          _iniciarAR();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar el árbol: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Iniciar experiencia AR
  void _iniciarAR() {
    if (_arbol == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ARViewScreen(
          arbol: _arbol!,
        ),
      ),
    );
  }
  
  // Mostrar código QR
  void _showQrCode(BuildContext context) {
    final appUrl = "https://memorial-app.com/arbol/${widget.arbolId}";
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Código QR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comparte este código para que otros puedan ver el árbol',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColorLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            QrImageView(
              data: appUrl,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              appUrl,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implementar compartir enlace
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Compartir enlace'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implementar guardar imagen QR
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Guardar QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Abrir enlace de YouTube
  Future<void> _openYouTubeLink(String url) async {
    if (url.isEmpty) return;
    
    // Validar que sea un enlace de YouTube
    if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El enlace no parece ser de YouTube'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir el enlace';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir el enlace: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  // Ver ubicación en mapa
  void _verEnMapa() {
    if (_arbol == null || !_arbol!.esPublico || _arbol!.ubicacion == null) {
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapaScreen(arbolSeleccionadoId: widget.arbolId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_arbol?.nombre ?? 'Detalles del árbol'),
        actions: [
          IconButton(
            onPressed: _showQrCode,
            icon: const Icon(Icons.qr_code),
            tooltip: 'Mostrar QR',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: ErrorMessage(
                    message: _errorMessage,
                    onRetry: _loadArbol,
                  ),
                )
              : _buildArbolContent(),
      floatingActionButton: _arbol != null
          ? FloatingActionButton.extended(
              onPressed: _iniciarAR,
              icon: const Icon(Icons.view_in_ar),
              label: const Text('Ver en AR'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
  
  // Construir contenido del árbol
  Widget _buildArbolContent() {
    if (_arbol == null) return const SizedBox.shrink();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de privacidad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _arbol!.esPublico ? AppTheme.primaryColor : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _arbol!.esPublico ? Icons.public : Icons.lock,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _arbol!.esPublico ? 'Público' : 'Privado',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Nombre y datos básicos
          Text(
            _arbol!.nombre,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Creado por ${_arbol!.usuarioNombre}',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textColorLight,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Fechas
          Row(
            children: [
              if (_arbol!.nacimiento != null) ...[
                Expanded(
                  child: _buildInfoCard(
                    title: 'Nacimiento',
                    value: _arbol!.nacimiento!,
                    icon: Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (_arbol!.fallecimiento != null) ...[
                Expanded(
                  child: _buildInfoCard(
                    title: 'Fallecimiento',
                    value: _arbol!.fallecimiento!,
                    icon: Icons.brightness_3,
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Vista previa del modelo 3D
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.primaryColorLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.view_in_ar,
                    size: 60,
                    color: AppTheme.primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Modelo 3D: ${_getModelName(_arbol!.modelo)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toca el botón "Ver en AR" para visualizar en realidad aumentada',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textColorLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Ubicación (si es público)
          if (_arbol!.esPublico && _arbol!.ubicacion != null) ...[
            const Text(
              'Ubicación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColorLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          _arbol!.ubicacion!.direccion,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  OutlinedButton.icon(
                    onPressed: _verEnMapa,
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Ver en mapa memorial'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
          
          // Enlace de canción (si hay)
          if (_arbol!.cancion != null && _arbol!.cancion!.isNotEmpty) ...[
            const Text(
              'Canción conmemorativa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            InkWell(
              onTap: () => _openYouTubeLink(_arbol!.cancion!),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Canción en YouTube',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _arbol!.cancion!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textColorLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new, color: Colors.red),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
          
          // Galería de imágenes
          if (_arbol!.imagenes.isNotEmpty) ...[
            const Text(
              'Galería de imágenes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            _buildImageGallery(),
            
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
  
  // Construir tarjeta de información
  Widget _buildInfoCard({required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColorLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textColorLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }
  
  // Construir galería de imágenes
  Widget _buildImageGallery() {
    if (_arbol!.imagenes.isEmpty) {
      return const Center(
        child: Text(
          'No hay imágenes para mostrar',
          style: TextStyle(color: AppTheme.textColorLight),
        ),
      );
    }
    
    return Column(
      children: [
        // Imagen principal
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade200,
            ),
            clipBehavior: Clip.hardEdge,
            child: CachedNetworkImage(
              imageUrl: _arbol!.imagenes[_currentImageIndex],
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error, color: AppTheme.errorColor),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Miniaturas
        if (_arbol!.imagenes.length > 1)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _arbol!.imagenes.length,
              itemBuilder: (context, index) {
                final bool isSelected = index == _currentImageIndex;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                        width: 2,
                      ),
                      color: Colors.grey.shade200,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: CachedNetworkImage(
                      imageUrl: _arbol!.imagenes[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.error, color: AppTheme.errorColor, size: 16),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
  
  // Obtener nombre amigable del modelo
  String _getModelName(String modeloId) {
    switch (modeloId) {
      case 'jabami_anime_tree_v2.glb':
        return 'Árbol estilo Anime';
      case 'low_poly_purple_flowers.glb':
        return 'Árbol con flores púrpura';
      case 'tree_elm.glb':
        return 'Olmo';
      case 'ficus_bonsai.glb':
        return 'Ficus Bonsai';
      case 'flowerpot.glb':
        return 'Maceta con flor';
      default:
        return modeloId;
    }
  }
}

// Importar pantalla del mapa
import 'package:arbolitos/screens/mapa/mapa_screen.dart';