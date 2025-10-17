import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScanButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const ScanButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.qr_code_scanner,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = backgroundColor ?? theme.colorScheme.primary;
    final defaultForegroundColor = foregroundColor ?? theme.colorScheme.onPrimary;

    // Si tiene label, usar ElevatedButton.icon, si no, usar IconButton estilizado
    if (label != null) {
      return SizedBox(
        width: width,
        height: height ?? 40,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : _handlePress,
          icon: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: defaultForegroundColor,
                  ),
                )
              : Icon(icon, size: 18),
          label: Text(
            label!,
            style: const TextStyle(fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: defaultBackgroundColor,
            foregroundColor: defaultForegroundColor,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
      );
    }

    // Botón solo icono
    return Container(
      width: width ?? 48,
      height: height ?? 48,
      decoration: BoxDecoration(
        color: isLoading 
            ? defaultBackgroundColor.withOpacity(0.6)
            : defaultBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _handlePress,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: padding ?? const EdgeInsets.all(12),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: defaultForegroundColor,
                    ),
                  )
                : Icon(
                    icon,
                    color: defaultForegroundColor,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }

  void _handlePress() {
    // Proporcionar feedback háptico
    HapticFeedback.lightImpact();
    
    // Llamar al callback
    onPressed?.call();
  }
}

// Variante especializada para escaneo RFID
class RFIDScanButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? label;
  final bool isScanning;
  final double? width;
  final double? height;

  const RFIDScanButton({
    super.key,
    required this.onPressed,
    this.label,
    this.isScanning = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ScanButton(
      onPressed: onPressed,
      icon: Icons.nfc,
      label: isScanning ? 'Escaneando...' : (label ?? 'RFID'),
      isLoading: isScanning,
      backgroundColor: Colors.teal,
      width: width,
      height: height,
    );
  }
}

// Variante especializada para escaneo de código de barras
class BarcodeScanButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? label;
  final bool isScanning;
  final double? width;
  final double? height;

  const BarcodeScanButton({
    super.key,
    required this.onPressed,
    this.label,
    this.isScanning = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ScanButton(
      onPressed: onPressed,
      icon: Icons.qr_code_scanner,
      label: isScanning ? 'Escaneando...' : (label ?? 'QR/Barcode'),
      isLoading: isScanning,
      backgroundColor: Colors.blue,
      width: width,
      height: height,
    );
  }
}

// Variante con escaneo dual (QR + RFID)
class DualScanButton extends StatefulWidget {
  final Function(String scanType)? onScanTypeChanged;
  final VoidCallback? onPressed;
  final bool isScanning;
  final String currentScanType; // 'qr' o 'rfid'

  const DualScanButton({
    super.key,
    this.onScanTypeChanged,
    this.onPressed,
    this.isScanning = false,
    this.currentScanType = 'qr',
  });

  @override
  State<DualScanButton> createState() => _DualScanButtonState();
}

class _DualScanButtonState extends State<DualScanButton> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón principal de escaneo
        ScanButton(
          onPressed: widget.onPressed,
          icon: widget.currentScanType == 'rfid' ? Icons.nfc : Icons.qr_code_scanner,
          label: widget.isScanning ? 'Escaneando...' : 'Escanear',
          isLoading: widget.isScanning,
          backgroundColor: widget.currentScanType == 'rfid' ? Colors.teal : Colors.blue,
        ),
        
        const SizedBox(width: 8),
        
        // Botón para cambiar tipo de escaneo
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: Theme.of(context).colorScheme.primary,
          ),
          onSelected: (String scanType) {
            widget.onScanTypeChanged?.call(scanType);
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'qr',
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: widget.currentScanType == 'qr' ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Código QR/Barras',
                    style: TextStyle(
                      fontWeight: widget.currentScanType == 'qr' 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                  if (widget.currentScanType == 'qr')
                    const Spacer(),
                  if (widget.currentScanType == 'qr')
                    const Icon(Icons.check, color: Colors.blue),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'rfid',
              child: Row(
                children: [
                  Icon(
                    Icons.nfc,
                    color: widget.currentScanType == 'rfid' ? Colors.teal : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RFID',
                    style: TextStyle(
                      fontWeight: widget.currentScanType == 'rfid' 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                  if (widget.currentScanType == 'rfid')
                    const Spacer(),
                  if (widget.currentScanType == 'rfid')
                    const Icon(Icons.check, color: Colors.teal),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Widget para mostrar el estado del escaneo
class ScanStatusIndicator extends StatelessWidget {
  final bool isScanning;
  final String? message;
  final IconData? icon;
  final Color? color;

  const ScanStatusIndicator({
    super.key,
    required this.isScanning,
    this.message,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!isScanning && message == null) {
      return const SizedBox.shrink();
    }

    final defaultColor = color ?? Theme.of(context).colorScheme.primary;
    final displayMessage = message ?? 'Escaneando...';
    final displayIcon = icon ?? (isScanning ? Icons.radar : Icons.check_circle);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: defaultColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: defaultColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isScanning)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: defaultColor,
              ),
            )
          else
            Icon(displayIcon, size: 16, color: defaultColor),
          const SizedBox(width: 8),
          Text(
            displayMessage,
            style: TextStyle(
              color: defaultColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}