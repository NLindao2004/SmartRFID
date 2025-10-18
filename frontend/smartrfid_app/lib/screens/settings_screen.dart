import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/inventory_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _inventoryService = InventoryService();
  
  User? _currentUser;
  bool _isLoading = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoSyncEnabled = true;
  bool _offlineModeEnabled = false;
  String _scannerType = 'camera';
  String _rfidPower = 'medium';
  int _syncInterval = 30; // minutes

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await _authService.getCurrentUser();
      setState(() => _currentUser = user);
      
      // TODO: Cargar configuraciones guardadas desde SharedPreferences
      // Por ahora usamos valores por defecto
      
    } catch (e) {
      _showError('Error cargando configuraciones: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuraciones'),
        backgroundColor: const Color.fromARGB(255, 233, 52, 52),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Sección de Usuario
                _buildSectionHeader('Usuario'),
                if (_currentUser != null) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        _currentUser!.firstName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(_currentUser!.fullName),
                    subtitle: Text('${_currentUser!.roleDisplayName} • ${_currentUser!.email}'),
                    trailing: const Icon(Icons.person),
                  ),
                  ListTile(
                    leading: const Icon(Icons.key),
                    title: const Text('Cambiar Contraseña'),
                    subtitle: const Text('Actualizar credenciales de acceso'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changePassword,
                  ),
                ],

                const Divider(),

                // Sección de Escaneo
                _buildSectionHeader('Escaneo y RFID'),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Tipo de Escáner'),
                  subtitle: Text(_getScannerTypeText()),
                  trailing: DropdownButton<String>(
                    value: _scannerType,
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(value: 'camera', child: Text('Cámara')),
                      DropdownMenuItem(value: 'external', child: Text('Externo')),
                      DropdownMenuItem(value: 'rfid', child: Text('RFID')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _scannerType = value);
                        _saveSetting('scanner_type', value);
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.nfc),
                  title: const Text('Potencia RFID'),
                  subtitle: Text(_getRFIDPowerText()),
                  trailing: DropdownButton<String>(
                    value: _rfidPower,
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Baja')),
                      DropdownMenuItem(value: 'medium', child: Text('Media')),
                      DropdownMenuItem(value: 'high', child: Text('Alta')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _rfidPower = value);
                        _saveSetting('rfid_power', value);
                      }
                    },
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up),
                  title: const Text('Sonidos'),
                  subtitle: const Text('Reproducir sonidos de confirmación'),
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() => _soundEnabled = value);
                    _saveSetting('sound_enabled', value.toString());
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration),
                  title: const Text('Vibración'),
                  subtitle: const Text('Vibrar al escanear elementos'),
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() => _vibrationEnabled = value);
                    _saveSetting('vibration_enabled', value.toString());
                    if (value) HapticFeedback.lightImpact();
                  },
                ),

                const Divider(),

                // Sección de Sincronización
                _buildSectionHeader('Sincronización'),
                SwitchListTile(
                  secondary: const Icon(Icons.sync),
                  title: const Text('Sincronización Automática'),
                  subtitle: const Text('Sincronizar datos automáticamente'),
                  value: _autoSyncEnabled,
                  onChanged: (value) {
                    setState(() => _autoSyncEnabled = value);
                    _saveSetting('auto_sync_enabled', value.toString());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Intervalo de Sincronización'),
                  subtitle: Text('Cada $_syncInterval minutos'),
                  trailing: DropdownButton<int>(
                    value: _syncInterval,
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15 min')),
                      DropdownMenuItem(value: 30, child: Text('30 min')),
                      DropdownMenuItem(value: 60, child: Text('1 hora')),
                      DropdownMenuItem(value: 120, child: Text('2 horas')),
                    ],
                    onChanged: _autoSyncEnabled ? (value) {
                      if (value != null) {
                        setState(() => _syncInterval = value);
                        _saveSetting('sync_interval', value.toString());
                      }
                    } : null,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sincronizar Ahora'),
                  subtitle: const Text('Forzar sincronización de datos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _syncNow,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.offline_pin),
                  title: const Text('Modo Offline'),
                  subtitle: const Text('Trabajar sin conexión a internet'),
                  value: _offlineModeEnabled,
                  onChanged: (value) {
                    setState(() => _offlineModeEnabled = value);
                    _saveSetting('offline_mode_enabled', value.toString());
                  },
                ),

                const Divider(),

                // Sección de Datos
                _buildSectionHeader('Datos'),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Descargar Maestros'),
                  subtitle: const Text('Actualizar SKUs y ubicaciones'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _downloadMasterData,
                ),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Enviar Transacciones'),
                  subtitle: const Text('Subir transacciones pendientes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _uploadTransactions,
                ),
                ListTile(
                  leading: const Icon(Icons.clear_all),
                  title: const Text('Limpiar Datos Locales'),
                  subtitle: const Text('Eliminar datos almacenados localmente'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _clearLocalData,
                ),

                const Divider(),

                // Sección de Información
                _buildSectionHeader('Información'),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Versión de la App'),
                  subtitle: const Text('v1.0.0 (Build 1)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showAbout,
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Reportar Problema'),
                  subtitle: const Text('Enviar reporte de errores'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _reportIssue,
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Ayuda'),
                  subtitle: const Text('Manual de usuario y FAQ'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showHelp,
                ),

                const SizedBox(height: 32),

                // Botón de cerrar sesión
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  String _getScannerTypeText() {
    switch (_scannerType) {
      case 'camera':
        return 'Cámara del dispositivo';
      case 'external':
        return 'Escáner externo';
      case 'rfid':
        return 'Lector RFID';
      default:
        return 'Desconocido';
    }
  }

  String _getRFIDPowerText() {
    switch (_rfidPower) {
      case 'low':
        return 'Baja potencia (corto alcance)';
      case 'medium':
        return 'Potencia media (alcance normal)';
      case 'high':
        return 'Alta potencia (largo alcance)';
      default:
        return 'Desconocido';
    }
  }

  Future<void> _saveSetting(String key, String value) async {
    // TODO: Implementar guardado en SharedPreferences
    debugPrint('Guardando configuración: $key = $value');
  }

  Future<void> _changePassword() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implementar sincronización real
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización completada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error en sincronización: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadMasterData() async {
    final confirmed = await _showConfirmDialog(
      'Descargar Maestros',
      '¿Desea descargar los datos maestros más recientes? Esto puede tardar unos minutos.',
    );
    
    if (confirmed) {
      setState(() => _isLoading = true);
      
      try {
        // TODO: Implementar descarga de maestros
        await Future.delayed(const Duration(seconds: 3));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datos maestros actualizados'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _showError('Error descargando maestros: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadTransactions() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implementar subida de transacciones
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacciones enviadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error enviando transacciones: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearLocalData() async {
    final confirmed = await _showConfirmDialog(
      'Limpiar Datos',
      '¿Está seguro que desea eliminar todos los datos locales? Esta acción no se puede deshacer.',
    );
    
    if (confirmed) {
      try {
        // TODO: Implementar limpieza de datos locales
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datos locales eliminados'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _showError('Error limpiando datos: $e');
      }
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'MASSLINE Smart RFID',
      applicationVersion: 'v1.0.0',
      applicationLegalese: '© 2024 MASSLINE. Todos los derechos reservados.',
      children: [
        const Text('Sistema de inventario inteligente con tecnología RFID y códigos de barras.'),
        const SizedBox(height: 16),
        const Text('Desarrollado para optimizar los procesos logísticos de MASSLINE.'),
      ],
    );
  }

  void _reportIssue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de reporte en desarrollo')),
    );
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manual de ayuda en desarrollo')),
    );
  }

  Future<void> _logout() async {
    final confirmed = await _showConfirmDialog(
      'Cerrar Sesión',
      '¿Está seguro que desea cerrar sesión?',
    );
    
    if (confirmed) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}

// Dialog para cambio de contraseña
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar Contraseña'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese su contraseña actual';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nueva contraseña',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != _newPasswordController.text) {
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
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _changePassword,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cambiar'),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Implementar cambio de contraseña real
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cambiando contraseña: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}