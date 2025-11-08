// lib/screens/galeria/galeria_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbolitos/config/theme.dart';
import 'package:arbolitos/models/arbol_model.dart';
import 'package:arbolitos/providers/auth_provider.dart';
import 'package:arbolitos/providers/arbol_provider.dart';
import 'package:arbolitos/screens/ver_arbol/ver_arbol_screen.dart';
import 'package:arbolitos/screens/editar_arbol/editar_arbol_screen.dart';
import 'package:arbolitos/widgets/common_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GaleriaScreen extends StatefulWidget {
  const GaleriaScreen({Key? key}) : super(key: key);

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  // Controlar la visualización del código QR
  String? _qrArbolId;
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
    
    // Recargar datos cuando se inicia la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }
  
  // Refrescar datos
  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final arbolProvider = Provider.of<ArbolProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await arbolProvider.fetchArbolesUsuario(authProvider.user!.uid);
    }
    
    setState(() {
      _isRefreshing = false;
    });
  }
  
  // Mostrar código QR
  void _showQrCode(BuildContext context, String arbolId) {
    final appUrl = "https://memorial-app.com/arbol/$arbolId";
    
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

  // Confirmar eliminación
  Future<void> _confirmDelete(BuildContext context, Arbol arbol) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: '¿Eliminar árbol?',
      message: '¿Estás seguro de que deseas eliminar "${arbol.nombre}"? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDanger: true,
    );
    
    if (confirmed == true) {
      // ignore: use_build_context_synchronously
      final arbolProvider = Provider.of<ArbolProvider>(context, listen: false);
      await arbolProvider.deleteArbol(arbol.id!);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final arbolProvider = Provider.of<ArbolProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final List<Arbol> arboles = arbolProvider.arboles;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Árboles Conmemorativos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: _isRefreshing
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : arboles.isEmpty
              ? _buildEmptyState(context)
              : _buildGaleriaContent(context, arboles),
    );
  }
  
  // Estado vacío
  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      title: 'Aún no tienes árboles',
      message: 'Crea tu primer árbol conmemorativo para honrar a tus seres queridos.',
      icon: Icons.park,
      buttonText: 'Crear mi primer árbol',
      onButtonPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CrearArbolScreen()),
        );
      },
    );
  }
  
  // Contenido de la galería
  Widget _buildGaleriaContent(BuildContext context, List<Arbol> arboles) {
    // Contar árboles públicos y privados
    final int arbolesPublicos = arboles.where((a) => a.esPublico).length;
    final int arbolesPrivados = arboles.length - arbolesPublicos;
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        slivers: [
          // Estadísticas
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColorLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(arboles.length, 'Total', Icons.forest),
                    _buildDivider(),
                    _buildStatCard(arbolesPublicos, 'Públicos', Icons.public),
                    _buildDivider(),
                    _buildStatCard(arbolesPrivados, 'Privados', Icons.lock),
                  ],
                ),
              ),
            ),
          ),
          
          // Lista de árboles
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final arbol = arboles[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ArbolCard(
                      id: arbol.id!,
                      nombre: arbol.nombre,
                      modelo: arbol.modelo,
                      nacimiento: arbol.nacimiento,
                      fallecimiento: arbol.fallecimiento,
                      esPublico: arbol.esPublico,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VerArbolScreen(arbolId: arbol.id!),
                          ),
                        );
                      },
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditarArbolScreen(arbolId: arbol.id!),
                          ),
                        );
                      },
                      onDelete: () => _confirmDelete(context, arbol),
                      onViewAr: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VerArbolScreen(arbolId: arbol.id!, iniciarAR: true),
                          ),
                        );
                      },
                      onGenerateQr: () => _showQrCode(context, arbol.id!),
                      onViewMap: arbol.esPublico && arbol.ubicacion != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapaScreen(arbolSeleccionadoId: arbol.id),
                                ),
                              );
                            }
                          : null,
                    ),
                  );
                },
                childCount: arboles.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Tarjeta de estadística
  Widget _buildStatCard(int count, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textColorLight,
          ),
        ),
      ],
    );
  }
  
  // Divider vertical
  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppTheme.borderColor,
    );
  }
}

// Importar pantalla de crear árbol
import 'package:arbolitos/screens/crear_arbol/crear_arbol_screen.dart';