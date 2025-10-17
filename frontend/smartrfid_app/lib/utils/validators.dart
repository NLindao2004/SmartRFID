import 'dart:ui';

import '../utils/constants.dart';

// =========================
// Base Validator Class
// =========================
abstract class Validator<T> {
  String? validate(T? value);
}

// =========================
// String Validators
// =========================
class RequiredValidator implements Validator<String> {
  final String? message;
  
  const RequiredValidator({this.message});

  @override
  String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return message ?? ErrorMessages.fieldRequired;
    }
    return null;
  }
}

class LengthValidator implements Validator<String> {
  final int? minLength;
  final int? maxLength;
  final String? message;
  
  const LengthValidator({
    this.minLength,
    this.maxLength,
    this.message,
  });

  @override
  String? validate(String? value) {
    if (value == null) return null;
    
    if (minLength != null && value.length < minLength!) {
      return message ?? 'Mínimo $minLength caracteres';
    }
    
    if (maxLength != null && value.length > maxLength!) {
      return message ?? 'Máximo $maxLength caracteres';
    }
    
    return null;
  }
}

class EmailValidator implements Validator<String> {
  final String? message;
  
  const EmailValidator({this.message});

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(ValidationConstants.emailPattern);
    if (!emailRegex.hasMatch(value)) {
      return message ?? ErrorMessages.invalidEmail;
    }
    
    return null;
  }
}

class PasswordValidator implements Validator<String> {
  final String? message;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;
  
  const PasswordValidator({
    this.message,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumbers = true,
    this.requireSpecialChars = false,
  });

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length < ValidationConstants.minPasswordLength) {
      return 'Mínimo ${ValidationConstants.minPasswordLength} caracteres';
    }
    
    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayúscula';
    }
    
    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return 'Debe contener al menos una minúscula';
    }
    
    if (requireNumbers && !value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }
    
    if (requireSpecialChars && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Debe contener al menos un carácter especial';
    }
    
    return null;
  }
}

class PatternValidator implements Validator<String> {
  final String pattern;
  final String? message;
  
  const PatternValidator({
    required this.pattern,
    this.message,
  });

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return message ?? 'Formato inválido';
    }
    
    return null;
  }
}

// =========================
// Numeric Validators
// =========================
class NumericValidator implements Validator<String> {
  final String? message;
  final bool allowDecimals;
  
  const NumericValidator({
    this.message,
    this.allowDecimals = false,
  });

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final pattern = allowDecimals 
        ? ValidationConstants.decimalPattern
        : ValidationConstants.numericPattern;
    
    final regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return message ?? 'Debe ser un número válido';
    }
    
    return null;
  }
}

class RangeValidator implements Validator<String> {
  final num? min;
  final num? max;
  final String? message;
  
  const RangeValidator({
    this.min,
    this.max,
    this.message,
  });

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final numValue = num.tryParse(value);
    if (numValue == null) {
      return 'Debe ser un número válido';
    }
    
    if (min != null && numValue < min!) {
      return message ?? 'Debe ser mayor o igual a $min';
    }
    
    if (max != null && numValue > max!) {
      return message ?? 'Debe ser menor o igual a $max';
    }
    
    return null;
  }
}

class QuantityValidator implements Validator<String> {
  final String? message;
  
  const QuantityValidator({this.message});

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Debe ser un número entero';
    }
    
    if (quantity < ValidationConstants.minQuantity) {
      return 'La cantidad debe ser mayor o igual a ${ValidationConstants.minQuantity}';
    }
    
    if (quantity > ValidationConstants.maxQuantity) {
      return 'La cantidad no puede ser mayor a ${ValidationConstants.maxQuantity}';
    }
    
    return null;
  }
}

// =========================
// Business Logic Validators
// =========================
class SKUValidator implements Validator<String> {
  final String? message;
  
  const SKUValidator({this.message});

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // Verificar longitud
    if (value.length < BarcodeConstants.skuMinLength ||
        value.length > BarcodeConstants.skuMaxLength) {
      return 'Código SKU debe tener entre ${BarcodeConstants.skuMinLength} y ${BarcodeConstants.skuMaxLength} caracteres';
    }
    
    // Verificar patrón
    final regex = RegExp(BarcodeConstants.skuPattern);
    if (!regex.hasMatch(value)) {
      // Verificar si comienza con algún prefijo válido
      final hasValidPrefix = BarcodeConstants.skuPrefixes
          .any((prefix) => value.startsWith(prefix));
      
      if (!hasValidPrefix) {
        return message ?? 'Código SKU inválido. Debe comenzar con: ${BarcodeConstants.skuPrefixes.join(", ")}';
      }
    }
    
    return null;
  }
}

class LocationValidator implements Validator<String> {
  final String? message;
  
  const LocationValidator({this.message});

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // Verificar patrón de ubicación
    final regex = RegExp(BarcodeConstants.locationPattern);
    if (!regex.hasMatch(value)) {
      // Verificar si comienza con algún prefijo válido
      final hasValidPrefix = BarcodeConstants.locationPrefixes
          .any((prefix) => value.startsWith(prefix));
      
      if (!hasValidPrefix) {
        return message ?? 'Código de ubicación inválido. Formato: LOC-A1-B2-C3';
      }
    }
    
    return null;
  }
}

class EPCValidator implements Validator<String> {
  final String? message;
  
  const EPCValidator({this.message});

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // Verificar longitud (EPC debe ser hexadecimal)
    if (value.length < RFIDConstants.epcMinLength ||
        value.length > RFIDConstants.epcMaxLength) {
      return 'EPC debe tener entre ${RFIDConstants.epcMinLength} y ${RFIDConstants.epcMaxLength} caracteres';
    }
    
    // Verificar que sea hexadecimal válido
    final hexRegex = RegExp(r'^[0-9A-Fa-f]+$');
    if (!hexRegex.hasMatch(value)) {
      return message ?? 'EPC debe contener solo caracteres hexadecimales (0-9, A-F)';
    }
    
    return null;
  }
}

class LotValidator implements Validator<String> {
  final String? message;
  
  const LotValidator({this.message});

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length > InventoryConstants.maxLotLength) {
      return 'Lote no puede exceder ${InventoryConstants.maxLotLength} caracteres';
    }
    
    final regex = RegExp(InventoryConstants.lotPattern);
    if (!regex.hasMatch(value)) {
      return message ?? 'Lote debe contener solo letras y números';
    }
    
    return null;
  }
}

class ExpiryDateValidator implements Validator<DateTime> {
  final String? message;
  final bool allowPastDates;
  
  const ExpiryDateValidator({
    this.message,
    this.allowPastDates = false,
  });

  @override
  String? validate(DateTime? value) {
    if (value == null) return null;
    
    final now = DateTime.now();
    
    if (!allowPastDates && value.isBefore(now)) {
      return message ?? 'La fecha de vencimiento no puede ser en el pasado';
    }
    
    // Verificar si está muy próxima a vencer
    final daysToExpiry = value.difference(now).inDays;
    if (daysToExpiry <= InventoryConstants.expiryCriticalDays) {
      return 'Producto próximo a vencer (${daysToExpiry} días)';
    }
    
    return null;
  }
}

// =========================
// Composite Validators
// =========================
class CompositeValidator implements Validator<String> {
  final List<Validator<String>> validators;
  
  const CompositeValidator(this.validators);

  @override
  String? validate(String? value) {
    for (final validator in validators) {
      final error = validator.validate(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}

// =========================
// Utility Classes
// =========================
class ValidationUtils {
  // Validar múltiples campos
  static Map<String, String?> validateFields(Map<String, dynamic> fields) {
    final errors = <String, String?>{};
    
    fields.forEach((fieldName, fieldData) {
      if (fieldData is Map) {
        final value = fieldData['value'];
        final validators = fieldData['validators'] as List<Validator>?;
        
        if (validators != null) {
          for (final validator in validators) {
            final error = validator.validate(value);
            if (error != null) {
              errors[fieldName] = error;
              break;
            }
          }
        }
      }
    });
    
    return errors;
  }
  
  // Verificar si un formulario es válido
  static bool isFormValid(Map<String, String?> errors) {
    return errors.values.every((error) => error == null);
  }
  
  // Limpiar y formatear string
  static String cleanString(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
  
  // Validar código de barras por tipo
  static String? validateBarcodeByType(String barcode) {
    // EAN-13
    if (RegExp(r'^\d{13}$').hasMatch(barcode)) {
      return validateEAN13(barcode);
    }
    
    // EAN-8
    if (RegExp(r'^\d{8}$').hasMatch(barcode)) {
      return validateEAN8(barcode);
    }
    
    // SKU
    if (RegExp(BarcodeConstants.skuPattern).hasMatch(barcode)) {
      return const SKUValidator().validate(barcode);
    }
    
    // Ubicación
    if (RegExp(BarcodeConstants.locationPattern).hasMatch(barcode)) {
      return const LocationValidator().validate(barcode);
    }
    
    return 'Formato de código no reconocido';
  }
  
  // Validar EAN-13 con dígito de control
  static String? validateEAN13(String ean) {
    if (ean.length != 13) {
      return 'EAN-13 debe tener exactamente 13 dígitos';
    }
    
    final digits = ean.split('').map(int.parse).toList();
    final checkDigit = digits.removeLast();
    
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += digits[i] * (i % 2 == 0 ? 1 : 3);
    }
    
    final calculatedCheck = (10 - (sum % 10)) % 10;
    
    if (calculatedCheck != checkDigit) {
      return 'Dígito de control EAN-13 inválido';
    }
    
    return null;
  }
  
  // Validar EAN-8 con dígito de control
  static String? validateEAN8(String ean) {
    if (ean.length != 8) {
      return 'EAN-8 debe tener exactamente 8 dígitos';
    }
    
    final digits = ean.split('').map(int.parse).toList();
    final checkDigit = digits.removeLast();
    
    int sum = 0;
    for (int i = 0; i < 7; i++) {
      sum += digits[i] * (i % 2 == 0 ? 3 : 1);
    }
    
    final calculatedCheck = (10 - (sum % 10)) % 10;
    
    if (calculatedCheck != checkDigit) {
      return 'Dígito de control EAN-8 inválido';
    }
    
    return null;
  }
  
  // Generar EPC válido (para testing)
  static String generateValidEPC() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'E200001B2F1F4B4F${random.toRadixString(16).toUpperCase().padLeft(8, '0')}';
  }
  
  // Verificar fuerza de contraseña
  static PasswordStrength checkPasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    if (password.length >= 16) score++;
    
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }
}

// =========================
// Enumerations
// =========================
enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong,
}

extension PasswordStrengthExtension on PasswordStrength {
  String get displayName {
    switch (this) {
      case PasswordStrength.weak:
        return 'Débil';
      case PasswordStrength.medium:
        return 'Media';
      case PasswordStrength.strong:
        return 'Fuerte';
      case PasswordStrength.veryStrong:
        return 'Muy Fuerte';
    }
  }
  
  Color get color {
    switch (this) {
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.medium:
        return AppColors.warning;
      case PasswordStrength.strong:
        return AppColors.info;
      case PasswordStrength.veryStrong:
        return AppColors.success;
    }
  }
}

// =========================
// Common Validator Combinations
// =========================
class CommonValidators {
  // Validador para username
  static final username = CompositeValidator([
    const RequiredValidator(message: 'Nombre de usuario requerido'),
    const LengthValidator(
      minLength: ValidationConstants.minUsernameLength,
      maxLength: ValidationConstants.maxUsernameLength,
    ),
    const PatternValidator(
      pattern: ValidationConstants.alphanumericPattern,
      message: 'Solo letras y números permitidos',
    ),
  ]);
  
  // Validador para password
  static final password = CompositeValidator([
    const RequiredValidator(message: 'Contraseña requerida'),
    const PasswordValidator(),
  ]);
  
  // Validador para email
  static final email = CompositeValidator([
    const RequiredValidator(message: 'Email requerido'),
    const EmailValidator(),
  ]);
  
  // Validador para cantidad
  static final quantity = CompositeValidator([
    const RequiredValidator(message: 'Cantidad requerida'),
    const QuantityValidator(),
  ]);
  
  // Validador para SKU
  static final sku = CompositeValidator([
    const RequiredValidator(message: 'Código SKU requerido'),
    const SKUValidator(),
  ]);
  
  // Validador para ubicación
  static final location = CompositeValidator([
    const RequiredValidator(message: 'Código de ubicación requerido'),
    const LocationValidator(),
  ]);
  
  // Validador para EPC
  static final epc = CompositeValidator([
    const RequiredValidator(message: 'EPC requerido'),
    const EPCValidator(),
  ]);
  
  // Validador para lote (opcional)
  static final lot = LotValidator();
  
  // Validador para notas (opcional)
  static final notes = LengthValidator(
    maxLength: ValidationConstants.maxNotesLength,
    message: 'Notas muy largas',
  );
}