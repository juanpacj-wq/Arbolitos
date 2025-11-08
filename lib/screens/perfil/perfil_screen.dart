// lib/screens/perfil/perfil_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arbolitos/config/theme.dart';
import 'package:arbolitos/providers/auth_provider.dart';
import 'package:arbolitos/providers/arbol_provider.dart';
import 'package:arbolitos/screens/auth/login_screen.dart';
import 'package:arbolitos/widgets/common_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({Key? key}) : super(key: key);

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _isLoading = false;
  String _appVersion = '';
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _getAppInfo();
  }
  
  // Obtener información de la aplicación
  Future<void> _getAppInfo() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'Versión ${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }
  
  // Seleccionar y actualizar foto de perfil
  Future<void> _updateProfilePicture() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 90,
      );
      
      if (pickedFile == null) return;
      
      setState(() {
        _isLoading = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final File imageFile = File(pickedFile.path);
      
      await authProvider.updateProfilePicture(imageFile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar foto de perfil: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Cambiar nombre de usuario
  Future<void> _updateDisplayName() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentName = authProvider.user?.displayName ?? 'Usuario';
    
    TextEditingController nameController = TextEditingController(text: currentName);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar nombre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(context);
                
                setState(() {
                  _isLoading = true;
                });
                
                try {
                  await authProvider.updateDisplayName(newName);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al actualizar nombre: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  
  // Cambiar contraseña
  Future<void> _changePassword() async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cambiar contraseña'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Contraseña actual
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña actual';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Nueva contraseña
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una nueva contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Confirmar nueva contraseña
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu nueva contraseña';
                    }
                    if (value != newPasswordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  
                  setState(() {
                    _isLoading = true;
                  });
                  
                  try {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    await authProvider.changePassword(
                      currentPasswordController.text,
                      newPasswordController.text,
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contraseña actualizada correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cambiar contraseña: $e'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Cerrar sesión
  Future<void> _logout() async {
    final bool confirm = await showConfirmationDialog(
      context: context,
      title: 'Cerrar sesión',
      message: '¿Estás seguro de que deseas cerrar sesión?',
      confirmText: 'Cerrar sesión',
      cancelText: 'Cancelar',
    ) ?? false;
    
    if (confirm) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
  
  // Abrir enlace de política de privacidad
  void _openPrivacyPolicy() async {
    const String url = 'https://www.memorial-app.com/privacidad';
    final Uri uri = Uri.parse(url);
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el enlace: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  // Abrir enlace de términos y condiciones
  void _openTermsAndConditions() async {
    const String url = 'https://www.memorial-app.com/terminos';
    final Uri uri = Uri.parse(url);
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el enlace: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  // Eliminar cuenta
  Future<void> _deleteAccount() async {
    final bool confirm = await showConfirmationDialog(
      context: context,
      title: 'Eliminar cuenta',
      message: 'Esta acción eliminará permanentemente tu cuenta y todos tus árboles. Esta acción no se puede deshacer. ¿Estás seguro?',
      confirmText: 'Eliminar cuenta',
      cancelText: 'Cancelar',
      isDanger: true,
    ) ?? false;
    
    if (confirm) {
      // Solicitar contraseña para confirmar
      final TextEditingController passwordController = TextEditingController();
      
      final bool passwordConfirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar con contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Por seguridad, ingresa tu contraseña para confirmar la eliminación de tu cuenta.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Confirmar eliminación'),
            ),
          ],
        ),
      ) ?? false;
      
      if (passwordConfirmed) {
        setState(() {
          _isLoading = true;
        });
        
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final arbolProvider = Provider.of<ArbolProvider>(context, listen: false);
          
          // Primero, eliminar todos los árboles del usuario
          for (var arbol in arbolProvider.arboles) {
            if (arbol.id != null) {
              await arbolProvider.deleteArbol(arbol.id!);
            }
          }
          
          // Luego, eliminar la cuenta
          await authProvider.deleteAccount(passwordController.text);
          
          // Navegar a la pantalla de login
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar cuenta: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final arbolProvider = Provider.of<ArbolProvider>(context);
    
    final user = authProvider.user;
    
    if (user == null) {
      // Si no hay usuario, mostrar pantalla de login
      return const LoginScreen();
    }
    
    // Contar árboles públicos y privados
    final int arbolesPublicos = arbolProvider.arboles.where((a) => a.esPublico).length;
    final int arbolesPrivados = arbolProvider.arboles.length - arbolesPublicos;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: () async {
                if (user.uid.isNotEmpty) {
                  await arbolProvider.fetchArbolesUsuario(user.uid);
                }
              },
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección de información de usuario
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColorLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Foto de perfil y nombre
                          Row(
                            children: [
                              // Foto de perfil
                              GestureDetector(
                                onTap: _updateProfilePicture,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: AppTheme.primaryColorLight,
                                      backgroundImage: user.photoURL != null
                                          ? NetworkImage(user.photoURL!)
                                          : null,
                                      child: user.photoURL == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 40,
                                              color: AppTheme.primaryColor,
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Información de usuario
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            user.displayName ?? 'Usuario',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textColor,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: _updateDisplayName,
                                          icon: const Icon(Icons.edit, size: 18),
                                          tooltip: 'Cambiar nombre',
                                          splashRadius: 20,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      user.email ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textColorLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Estadísticas
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(
                                icon: Icons.forest,
                                label: 'Total',
                                value: arbolProvider.arboles.length.toString(),
                              ),
                              _buildStatItem(
                                icon: Icons.public,
                                label: 'Públicos',
                                value: arbolesPublicos.toString(),
                              ),
                              _buildStatItem(
                                icon: Icons.lock,
                                label: 'Privados',
                                value: arbolesPrivados.toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Sección de opciones de cuenta
                    const Text(
                      'Cuenta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildOptionItem(
                      icon: Icons.lock,
                      title: 'Cambiar contraseña',
                      onTap: _changePassword,
                    ),
                    
                    const Divider(),
                    
                    // Sección de ajustes
                    const SizedBox(height: 16),
                    const Text(
                      'Preferencias',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildOptionItem(
                      icon: Icons.notifications,
                      title: 'Notificaciones',
                      onTap: () {
                        // TODO: Implementar pantalla de notificaciones
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Próximamente: Configuración de notificaciones'),
                          ),
                        );
                      },
                    ),
                    
                    const Divider(),
                    
                    _buildOptionItem(
                      icon: Icons.language,
                      title: 'Idioma',
                      trailing: const Text(
                        'Español',
                        style: TextStyle(
                          color: AppTheme.textColorLight,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () {
                        // TODO: Implementar selector de idioma
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Próximamente: Cambio de idioma'),
                          ),
                        );
                      },
                    ),
                    
                    const Divider(),
                    
                    // Sección de legal
                    const SizedBox(height: 16),
                    const Text(
                      'Legal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildOptionItem(
                      icon: Icons.privacy_tip,
                      title: 'Política de privacidad',
                      onTap: _openPrivacyPolicy,
                    ),
                    
                    const Divider(),
                    
                    _buildOptionItem(
                      icon: Icons.description,
                      title: 'Términos y condiciones',
                      onTap: _openTermsAndConditions,
                    ),
                    
                    const Divider(),
                    
                    // Sección de información
                    const SizedBox(height: 16),
                    const Text(
                      'Información',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildOptionItem(
                      icon: Icons.info,
                      title: 'Acerca de',
                      trailing: Text(
                        _appVersion,
                        style: const TextStyle(
                          color: AppTheme.textColorLight,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () {
                        // Mostrar diálogo con información de la app
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Memorial App'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 16),
                                const Text(
                                  'Una aplicación para honrar la memoria de tus seres queridos a través de árboles conmemorativos en realidad aumentada.',
                                ),
                                const SizedBox(height: 16),
                                Text('Versión: $_appVersion'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const Divider(),
                    
                    _buildOptionItem(
                      icon: Icons.support,
                      title: 'Soporte',
                      onTap: () async {
                        // Abrir correo para soporte
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'soporte@memorial-app.com',
                          queryParameters: {
                            'subject': 'Soporte Memorial App - ${user.uid}',
                            'body': 'Descripción del problema:',
                          },
                        );
                        
                        try {
                          await launchUrl(emailUri);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No se pudo abrir el correo: $e'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      },
                    ),
                    
                    const Divider(),
                    
                    // Sección de peligro (eliminar cuenta)
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zona de peligro',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          const Text(
                            'Las acciones en esta sección son irreversibles.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textColorLight,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          _buildOptionItem(
                            icon: Icons.delete_forever,
                            title: 'Eliminar cuenta',
                            iconColor: Colors.red,
                            titleColor: Colors.red,
                            onTap: _deleteAccount,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
  
  // Construir un elemento de estadísticas
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
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
  
  // Construir un elemento de opción
  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = AppTheme.textColor,
    Color titleColor = AppTheme.textColor,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(
        Icons.chevron_right,
        color: AppTheme.textColorLight,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}