import 'package:flutter_test/flutter_test.dart';
import 'package:sk58_printer/sk58_printer.dart';

void main() {
  group('BarcodeType', () {
    test('has correct command codes', () {
      expect(BarcodeType.code128.commandCode, 73);
      expect(BarcodeType.ean13.commandCode, 67);
      expect(BarcodeType.upcA.commandCode, 65);
      expect(BarcodeType.code39.commandCode, 69);
    });

    test('has display names', () {
      expect(BarcodeType.code128.displayName, 'Code 128');
      expect(BarcodeType.ean13.displayName, 'EAN-13');
      expect(BarcodeType.upcA.displayName, 'UPC-A');
      expect(BarcodeType.code39.displayName, 'Code 39');
    });
  });

  group('BarcodeHriPosition', () {
    test('has correct values', () {
      expect(BarcodeHriPosition.none.value, 0);
      expect(BarcodeHriPosition.above.value, 1);
      expect(BarcodeHriPosition.below.value, 2);
      expect(BarcodeHriPosition.both.value, 3);
    });
  });

  group('BarcodeConfig', () {
    test('has correct defaults', () {
      const config = BarcodeConfig();
      expect(config.height, 80);
      expect(config.width, 3);
      expect(config.hriPosition, BarcodeHriPosition.below);
    });

    test('accepts custom values', () {
      const config = BarcodeConfig(
        height: 100,
        width: 4,
        hriPosition: BarcodeHriPosition.above,
      );
      expect(config.height, 100);
      expect(config.width, 4);
      expect(config.hriPosition, BarcodeHriPosition.above);
    });
  });

  group('EscPosCommands.printBarcode', () {
    test('generates valid Code128 commands', () {
      final commands = EscPosCommands.printBarcode('ABC', BarcodeType.code128);

      // Should contain GS k command
      expect(commands, contains(0x1D)); // GS
      expect(commands, contains(0x6B)); // k
      expect(commands, contains(73)); // Code128 type
    });

    test('generates valid EAN13 commands', () {
      final commands = EscPosCommands.printBarcode(
        '5901234123457',
        BarcodeType.ean13,
      );

      expect(commands, contains(0x1D)); // GS
      expect(commands, contains(0x6B)); // k
      expect(commands, contains(67)); // EAN13 type
    });

    test('includes height command', () {
      final commands = EscPosCommands.printBarcode(
        'TEST',
        BarcodeType.code128,
        config: const BarcodeConfig(height: 100),
      );

      // GS h n (set height)
      expect(commands.contains(0x68), true); // h command
      expect(commands.contains(100), true); // height value
    });

    test('includes width command', () {
      final commands = EscPosCommands.printBarcode(
        'TEST',
        BarcodeType.code128,
        config: const BarcodeConfig(width: 4),
      );

      // GS w n (set width)
      expect(commands.contains(0x77), true); // w command
      expect(commands.contains(4), true); // width value
    });

    test('includes HRI position command', () {
      final commands = EscPosCommands.printBarcode(
        'TEST',
        BarcodeType.code128,
        config: const BarcodeConfig(hriPosition: BarcodeHriPosition.above),
      );

      // GS H n (set HRI position)
      expect(commands.contains(0x48), true); // H command
      expect(commands.contains(1), true); // above value
    });
  });

  group('Barcode validation', () {
    test('EAN13 requires 12-13 digits', () {
      // Valid
      expect(
        () => EscPosCommands.printBarcode('590123412345', BarcodeType.ean13),
        returnsNormally,
      );
      expect(
        () => EscPosCommands.printBarcode('5901234123457', BarcodeType.ean13),
        returnsNormally,
      );

      // Invalid - wrong length
      expect(
        () => EscPosCommands.printBarcode('12345', BarcodeType.ean13),
        throwsA(isA<BarcodeException>()),
      );
    });

    test('EAN13 requires only digits', () {
      expect(
        () => EscPosCommands.printBarcode('59012341234AB', BarcodeType.ean13),
        throwsA(isA<BarcodeException>()),
      );
    });

    test('UPC-A requires 11-12 digits', () {
      // Valid
      expect(
        () => EscPosCommands.printBarcode('01234567890', BarcodeType.upcA),
        returnsNormally,
      );
      expect(
        () => EscPosCommands.printBarcode('012345678905', BarcodeType.upcA),
        returnsNormally,
      );

      // Invalid
      expect(
        () => EscPosCommands.printBarcode('1234', BarcodeType.upcA),
        throwsA(isA<BarcodeException>()),
      );
    });

    test('Code39 validates characters', () {
      // Valid characters
      expect(
        () => EscPosCommands.printBarcode('ABC123', BarcodeType.code39),
        returnsNormally,
      );
      expect(
        () => EscPosCommands.printBarcode('TEST-123', BarcodeType.code39),
        returnsNormally,
      );

      // Invalid characters (lowercase not converted)
      expect(
        () => EscPosCommands.printBarcode('abc@123', BarcodeType.code39),
        throwsA(isA<BarcodeException>()),
      );
    });

    test('Code128 allows ASCII 0-127', () {
      // Valid
      expect(
        () => EscPosCommands.printBarcode('Hello World!', BarcodeType.code128),
        returnsNormally,
      );
    });
  });

  group('BarcodeException', () {
    test('has correct message', () {
      final exception = BarcodeException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.toString(), 'BarcodeException: Test error');
    });
  });
}
