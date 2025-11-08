// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbolitos/config/theme.dart';
import 'package:arbolitos/providers/auth_provider.dart';
import 'package:arbolitos/providers/arbol_provider.dart';
import 'package:arbolitos/screens/galeria/galeria_screen.dart';
import 'package:arbolitos/screens/mapa/mapa_screen.dart';
import 'package:arbolitos/screens/perfil/perfil_screen.dart';
import 'package:arbolitos/screens/crear_arbol/crear_arbol_screen.dart'; // <-- IMPORT MOVIMIDO AQUÍ

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  // Páginas para la navegación inferior
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar páginas
    _pages = [
      const GaleriaScreen(),
      const MapaScreen(),
      const PerfilScreen(),
    ];
    
    // Cargar datos iniciales
    _loadInitialData();
  }
  
  // Cargar datos iniciales de árboles
  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final arbolProvider = Provider.of<ArbolProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await arbolProvider.fetchArbolesUsuario(authProvider.user!.uid);
      await arbolProvider.fetchArbolesPublicos();
    }
  }
  
  // Cambiar de página
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  // FAB para crear nuevo árbol
  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Navegar a la pantalla de crear árbol
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CrearArbolScreen(),
          ),
        );
      },
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textColorLight,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            activeIcon: Icon(Icons.photo_library),
            label: 'Galería',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
} 