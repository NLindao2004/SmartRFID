import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Interface abstracta para adaptadores RFID
abstract class RFIDAdapter {
  Future<List<String>> scanRFIDTags({Duration? timeout});
  Future<bool> writeTag(String epc, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> readTag(String epc);
  Future<bool> commissionTag(String epc, String skuCode, int quantity);
  Future<bool> findTag(String epc);
  Future<bool> isAvailable();
  Stream<RFIDScanResult> get tagStream;
}

// Implementación para lector RFID portátil (Zebra, Impinj, etc.)
class PortableRFIDAdapter implements RFIDAdapter {
  static const MethodChannel _channel = MethodChannel('com.massline.smartrfid/rfid');
  
  final StreamController<RFIDScanResult> _tagController = StreamController<RFIDScanResult>.broadcast();
  bool _isConnected = false;
  bool _isScanning = false;
  String? _deviceModel;
  RFIDConfig _config = RFIDConfig();

  @override
  Stream<RFIDScanResult> get tagStream => _tagController.stream;

  // Propiedades
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  String? get deviceModel => _deviceModel;

  // Inicializar y conectar al lector RFID
  Future<bool> initialize() async {
    try {
      final Map<String, dynamic> result = await _channel.invokeMethod('initialize');
      
      _isConnected = result['connected'] ?? false;
      _deviceModel = result['model'];
      
      if (_isConnected) {
        _startListening();
        await _configureReader();
      }
      
      return _isConnected;
    } catch (e) {
      debugPrint('RFID initialization error: $e');
      return false;
    }
  }

  // Configurar parámetros del lector
  Future<bool> _configureReader() async {
    try {
      await _channel.invokeMethod('configure', {
        'power': _config.power,
        'session': _config.session,
        'population': _config.population,
        'enableFilter': _config.enableFilter,
      });
      return true;
    } catch (e) {
      debugPrint('RFID configuration error: $e');
      return false;
    }
  }

  @override
  Future<List<String>> scanRFIDTags({Duration? timeout}) async {
    if (!_isConnected) {
      throw Exception('Lector RFID no conectado');
    }

    if (_isScanning) {
      throw Exception('Escaneo ya en progreso');
    }

    try {
      _isScanning = true;
      
      final List<String> tags = [];
      final completer = Completer<List<String>>();
      final scanTimeout = timeout ?? const Duration(seconds: 10);
      
      // Configurar timer para timeout
      Timer? timeoutTimer = Timer(scanTimeout, () {
        if (!completer.isCompleted) {
          completer.complete(tags);
        }
      });

      // Escuchar tags del stream
      StreamSubscription? subscription;
      subscription = tagStream.listen((result) {
        if (!tags.contains(result.epc)) {
          tags.add(result.epc);
        }
      });

      // Iniciar escaneo
      await _channel.invokeMethod('startScan');

      final result = await completer.future;
      
      // Limpiar
      await _channel.invokeMethod('stopScan');
      timeoutTimer?.cancel();
      subscription?.cancel();
      
      return result;
    } catch (e) {
      debugPrint('RFID scan error: $e');
      return [];
    } finally {
      _isScanning = false;
    }
  }

  // Iniciar escaneo continuo
  Future<bool> startContinuousScan() async {
    if (!_isConnected || _isScanning) return false;

    try {
      _isScanning = true;
      await _channel.invokeMethod('startContinuousScan');
      return true;
    } catch (e) {
      debugPrint('Start continuous scan error: $e');
      _isScanning = false;
      return false;
    }
  }

  // Detener escaneo continuo
  Future<bool> stopContinuousScan() async {
    if (!_isScanning) return true;

    try {
      await _channel.invokeMethod('stopScan');
      _isScanning = false;
      return true;
    } catch (e) {
      debugPrint('Stop scan error: $e');
      return false;
    }
  }

  @override
  Future<bool> writeTag(String epc, Map<String, dynamic> data) async {
    if (!_isConnected) return false;

    try {
      final bool success = await _channel.invokeMethod('writeTag', {
        'epc': epc,
        'data': data,
      });
      return success;
    } catch (e) {
      debugPrint('Write tag error: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> readTag(String epc) async {
    if (!_isConnected) return null;

    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('readTag', {
        'epc': epc,
      });
      
      return Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint('Read tag error: $e');
      return null;
    }
  }

  @override
  Future<bool> commissionTag(String epc, String skuCode, int quantity) async {
    if (!_isConnected) return false;

    try {
      final data = {
        'sku_code': skuCode,
        'quantity': quantity,
        'commissioned_date': DateTime.now().toIso8601String(),
        'status': 'commissioned',
      };

      return await writeTag(epc, data);
    } catch (e) {
      debugPrint('Commission tag error: $e');
      return false;
    }
  }

  @override
  Future<bool> findTag(String epc) async {
    if (!_isConnected) return false;

    try {
      // Activar modo Geiger para localización
      await _channel.invokeMethod('startGeigerMode', {'targetEPC': epc});
      return true;
    } catch (e) {
      debugPrint('Find tag error: $e');
      return false;
    }
  }

  // Detener modo Geiger
  Future<bool> stopGeigerMode() async {
    if (!_isConnected) return false;

    try {
      await _channel.invokeMethod('stopGeigerMode');
      return true;
    } catch (e) {
      debugPrint('Stop Geiger mode error: $e');
      return false;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final bool available = await _channel.invokeMethod('isAvailable');
      return available;
    } catch (e) {
      debugPrint('RFID availability check error: $e');
      return false;
    }
  }

  // Configurar potencia
  Future<bool> setPower(int powerLevel) async {
    if (!_isConnected) return false;
    
    try {
      _config = _config.copyWith(power: powerLevel);
      await _channel.invokeMethod('setPower', {'power': powerLevel});
      return true;
    } catch (e) {
      debugPrint('Set power error: $e');
      return false;
    }
  }

  // Obtener información del lector
  Future<RFIDReaderInfo?> getReaderInfo() async {
    if (!_isConnected) return null;

    try {
      final Map<dynamic, dynamic> info = await _channel.invokeMethod('getReaderInfo');
      return RFIDReaderInfo.fromMap(Map<String, dynamic>.from(info));
    } catch (e) {
      debugPrint('Get reader info error: $e');
      return null;
    }
  }

  // Escuchar eventos del lector
  void _startListening() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onTagRead':
          final Map<String, dynamic> tagData = Map<String, dynamic>.from(call.arguments);
          final result = RFIDScanResult.fromMap(tagData);
          _tagController.add(result);
          break;
          
        case 'onGeigerUpdate':
          final int signalStrength = call.arguments['signalStrength'];
          _tagController.add(RFIDScanResult.geiger(
            epc: call.arguments['epc'],
            signalStrength: signalStrength,
          ));
          break;
          
        case 'onReaderDisconnected':
          _isConnected = false;
          _isScanning = false;
          break;
          
        case 'onError':
          final String error = call.arguments['error'];
          debugPrint('RFID Reader Error: $error');
          break;
      }
    });
  }

  // Desconectar lector
  Future<bool> disconnect() async {
    try {
      if (_isScanning) {
        await stopContinuousScan();
      }
      
      await _channel.invokeMethod('disconnect');
      _isConnected = false;
      return true;
    } catch (e) {
      debugPrint('Disconnect error: $e');
      return false;
    }
  }

  void dispose() {
    disconnect();
    _tagController.close();
  }
}

// Implementación simulada para desarrollo/testing
class SimulatedRFIDAdapter implements RFIDAdapter {
  final StreamController<RFIDScanResult> _tagController = StreamController<RFIDScanResult>.broadcast();
  bool _isScanning = false;
  
  // EPCs simulados para testing
  static final List<String> _simulatedEPCs = [
    'E200001B2F1F4B4F3F3E3D3C',
    'E200001B2F1F4B4F3F3E3D3D',
    'E200001B2F1F4B4F3F3E3D3E',
    'E200001B2F1F4B4F3F3E3D3F',
    'E200001B2F1F4B4F3F3E3D40',
  ];

  @override
  Stream<RFIDScanResult> get tagStream => _tagController.stream;

  @override
  Future<List<String>> scanRFIDTags({Duration? timeout}) async {
    _isScanning = true;
    
    try {
      // Simular tiempo de escaneo
      await Future.delayed(const Duration(seconds: 2));
      
      final random = Random();
      final count = random.nextInt(4) + 1; // 1-4 tags
      
      final scannedTags = <String>[];
      for (int i = 0; i < count; i++) {
        final epc = _simulatedEPCs[random.nextInt(_simulatedEPCs.length)];
        if (!scannedTags.contains(epc)) {
          scannedTags.add(epc);
          
          // Emitir por el stream también
          _tagController.add(RFIDScanResult(
            epc: epc,
            rssi: -30 - random.nextInt(40),
            timestamp: DateTime.now(),
            antennaPort: random.nextInt(4) + 1,
          ));
        }
      }
      
      return scannedTags;
    } finally {
      _isScanning = false;
    }
  }

  @override
  Future<bool> writeTag(String epc, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Simulated write to $epc: $data');
    return true;
  }

  @override
  Future<Map<String, dynamic>?> readTag(String epc) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'sku_code': 'SKU${Random().nextInt(1000000)}',
      'quantity': Random().nextInt(100) + 1,
      'commissioned_date': DateTime.now().subtract(Duration(days: Random().nextInt(30))).toIso8601String(),
      'status': 'commissioned',
    };
  }

  @override
  Future<bool> commissionTag(String epc, String skuCode, int quantity) async {
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('Simulated commission: $epc -> $skuCode ($quantity)');
    return true;
  }

  @override
  Future<bool> findTag(String epc) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simular señales Geiger
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isScanning) {
        timer.cancel();
        return;
      }
      
      final strength = Random().nextInt(100);
      _tagController.add(RFIDScanResult.geiger(
        epc: epc,
        signalStrength: strength,
      ));
      
      if (timer.tick > 25) { // Detener después de 5 segundos
        timer.cancel();
      }
    });
    
    _isScanning = true;
    return true;
  }

  @override
  Future<bool> isAvailable() async {
    return true; // Siempre disponible para simulación
  }

  void dispose() {
    _tagController.close();
  }
}

// Configuración del lector RFID
class RFIDConfig {
  final int power; // 0-100
  final int session; // 0-3
  final int population; // Número esperado de tags
  final bool enableFilter;
  final Duration scanTimeout;

  RFIDConfig({
    this.power = 75,
    this.session = 1,
    this.population = 100,
    this.enableFilter = false,
    this.scanTimeout = const Duration(seconds: 10),
  });

  RFIDConfig copyWith({
    int? power,
    int? session,
    int? population,
    bool? enableFilter,
    Duration? scanTimeout,
  }) {
    return RFIDConfig(
      power: power ?? this.power,
      session: session ?? this.session,
      population: population ?? this.population,
      enableFilter: enableFilter ?? this.enableFilter,
      scanTimeout: scanTimeout ?? this.scanTimeout,
    );
  }
}

// Resultado de escaneo RFID
class RFIDScanResult {
  final String epc;
  final int? rssi;
  final DateTime timestamp;
  final int? antennaPort;
  final int? signalStrength; // Para modo Geiger
  final Map<String, dynamic>? userData;

  RFIDScanResult({
    required this.epc,
    this.rssi,
    required this.timestamp,
    this.antennaPort,
    this.signalStrength,
    this.userData,
  });

  factory RFIDScanResult.geiger({
    required String epc,
    required int signalStrength,
  }) {
    return RFIDScanResult(
      epc: epc,
      timestamp: DateTime.now(),
      signalStrength: signalStrength,
    );
  }

  factory RFIDScanResult.fromMap(Map<String, dynamic> map) {
    return RFIDScanResult(
      epc: map['epc'] ?? '',
      rssi: map['rssi'],
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      antennaPort: map['antennaPort'],
      signalStrength: map['signalStrength'],
      userData: map['userData'] != null 
          ? Map<String, dynamic>.from(map['userData'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'epc': epc,
      'rssi': rssi,
      'timestamp': timestamp.toIso8601String(),
      'antennaPort': antennaPort,
      'signalStrength': signalStrength,
      'userData': userData,
    };
  }

  bool get isGeigerResult => signalStrength != null;
  
  String get displayName {
    if (isGeigerResult) {
      return 'Señal: $signalStrength%';
    }
    return 'EPC: ${epc.substring(0, 12)}...';
  }
}

// Información del lector RFID
class RFIDReaderInfo {
  final String model;
  final String serialNumber;
  final String firmwareVersion;
  final List<int> supportedFrequencies;
  final int maxPower;
  final bool supportsWrite;

  RFIDReaderInfo({
    required this.model,
    required this.serialNumber,
    required this.firmwareVersion,
    required this.supportedFrequencies,
    required this.maxPower,
    required this.supportsWrite,
  });

  factory RFIDReaderInfo.fromMap(Map<String, dynamic> map) {
    return RFIDReaderInfo(
      model: map['model'] ?? 'Unknown',
      serialNumber: map['serialNumber'] ?? 'Unknown',
      firmwareVersion: map['firmwareVersion'] ?? 'Unknown',
      supportedFrequencies: List<int>.from(map['supportedFrequencies'] ?? []),
      maxPower: map['maxPower'] ?? 100,
      supportsWrite: map['supportsWrite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'model': model,
      'serialNumber': serialNumber,
      'firmwareVersion': firmwareVersion,
      'supportedFrequencies': supportedFrequencies,
      'maxPower': maxPower,
      'supportsWrite': supportsWrite,
    };
  }
}

// Factory para crear adaptadores
class RFIDAdapterFactory {
  static RFIDAdapter create({bool useSimulated = false}) {
    if (useSimulated || kDebugMode) {
      return SimulatedRFIDAdapter();
    }
    return PortableRFIDAdapter();
  }
}

// Enumeración de tipos de sesión RFID
enum RFIDSession {
  s0, s1, s2, s3
}

// Enumeración de estados de tag
enum TagState {
  acknowledged,
  unacknowledged,
  any
}