// lib/widgets/common_widgets.dart

import 'package:flutter/material.dart';
import 'package:arbolitos/config/theme.dart';

// Widget de campo de texto personalizado
class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  
  const CustomTextField({
    Key? key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffix,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textColorLight),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.textColorLight) : null,
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textColor,
          ),
        ),
      ],
    );
  }
}

// Widget de botón principal
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final IconData? icon;
  
  const PrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

// Widget de mensaje de error
class ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const ErrorMessage({
    Key? key,
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: AppTheme.errorColor.withOpacity(0.8),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget para estado vacío
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  
  const EmptyState({
    Key? key,
    required this.title,
    required this.message,
    required this.icon,
    this.buttonText,
    this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textColorLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                text: buttonText!,
                onPressed: onButtonPressed!,
                icon: Icons.add,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget para tarjeta de árbol
class ArbolCard extends StatelessWidget {
  final String id;
  final String nombre;
  final String modelo;
  final String? nacimiento;
  final String? fallecimiento;
  final bool esPublico;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewAr;
  final VoidCallback onGenerateQr;
  final VoidCallback? onViewMap;
  
  const ArbolCard({
    Key? key,
    required this.id,
    required this.nombre,
    required this.modelo,
    this.nacimiento,
    this.fallecimiento,
    required this.esPublico,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onViewAr,
    required this.onGenerateQr,
    this.onViewMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con nombre y estado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: esPublico ? AppTheme.primaryColor : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          esPublico ? Icons.public : Icons.lock,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          esPublico ? 'Público' : 'Privado',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Modelo y fechas
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.view_in_ar,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getModelName(modelo),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textColorLight,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (nacimiento != null || fallecimiento != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (nacimiento != null) ...[
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.textColorLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        nacimiento!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColorLight,
                        ),
                      ),
                    ],
                    if (nacimiento != null && fallecimiento != null) ...[
                      const SizedBox(width: 8),
                      const Text(
                        '-',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColorLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (fallecimiento != null) ...[
                      const Icon(
                        Icons.brightness_3,
                        size: 16,
                        color: AppTheme.textColorLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fallecimiento!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColorLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Acciones principales
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.edit,
                        label: 'Editar',
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        icon: Icons.delete,
                        label: 'Eliminar',
                        onTap: onDelete,
                        color: AppTheme.errorColor,
                      ),
                    ],
                  ),
                  
                  // Acciones secundarias
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.view_in_ar,
                        label: 'AR',
                        onTap: onViewAr,
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        icon: Icons.qr_code,
                        label: 'QR',
                        onTap: onGenerateQr,
                      ),
                      if (onViewMap != null) ...[
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: Icons.map,
                          label: 'Mapa',
                          onTap: onViewMap!,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Construir botón de acción
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? AppTheme.primaryColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? AppTheme.textColorLight,
              ),
            ),
          ],
        ),
      ),
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

// Diálogo de confirmación
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmText,
  required String cancelText,
  bool isDanger = false,
}) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: isDanger ? AppTheme.errorColor : AppTheme.primaryColor,
          ),
          child: Text(confirmText),
        ),
      ],
    ),
  );
}