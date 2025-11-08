// lib/screens/auth/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbolitos/config/theme.dart';
import 'package:arbolitos/providers/auth_provider.dart';
import 'package:arbolitos/widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Método para restablecer contraseña
  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final bool success = await authProvider.resetPassword(
        _emailController.text.trim(),
      );
      
      if (success && mounted) {
        setState(() {
          _emailSent = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textColor,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessView(context) : _buildFormView(context, authProvider),
        ),
      ),
    );
  }

  // Vista del formulario
  Widget _buildFormView(BuildContext context, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icono y título
        Center(
          child: Column(
            children: [
              Icon(
                Icons.lock_reset,
                size: 70,
                color: AppTheme.primaryColor.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recupera tu contraseña',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tu correo electrónico para recibir instrucciones para restablecer tu contraseña',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textColorLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Formulario
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo de correo electrónico
              CustomTextField(
                label: 'Correo electrónico',
                hint: 'ejemplo@correo.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu correo electrónico';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Ingresa un correo electrónico válido';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Mensajes de error
              if (authProvider.errorMessage.isNotEmpty) ...[
                ErrorMessage(
                  message: authProvider.errorMessage,
                ),
                const SizedBox(height: 16),
              ],
              
              // Botón de enviar
              PrimaryButton(
                text: 'Enviar instrucciones',
                isLoading: authProvider.isLoading,
                onPressed: _resetPassword,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Vista de éxito
  Widget _buildSuccessView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icono de éxito
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColorLight.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Mensaje de éxito
        const Text(
          '¡Correo enviado!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Hemos enviado instrucciones para restablecer tu contraseña a ${_emailController.text}',
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textColorLight,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Por favor revisa tu correo y sigue las instrucciones.',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textColorLight,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 40),
        
        // Botón para volver al inicio de sesión
        PrimaryButton(
          text: 'Volver al inicio de sesión',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        
        const SizedBox(height: 16),
        
        // No recibiste el correo
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: const Text(
            '¿No recibiste el correo? Intentar de nuevo',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}