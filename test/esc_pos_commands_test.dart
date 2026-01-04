import 'package:flutter_test/flutter_test.dart';
import 'package:sk58_printer/sk58_printer.dart';

void main() {
  group('EscPosCommands', () {
    test('initialize returns correct bytes', () {
      expect(EscPosCommands.initialize, [0x1B, 0x40]);
    });

    test('lineFeed returns correct bytes', () {
      expect(EscPosCommands.lineFeed, [0x0A]);
    });

    test('feedLines returns correct number of line feeds', () {
      expect(EscPosCommands.feedLines(3), [0x0A, 0x0A, 0x0A]);
      expect(EscPosCommands.feedLines(1), [0x0A]);
      expect(EscPosCommands.feedLines(0), <int>[]);
    });

    test('setAlignment returns correct bytes', () {
      expect(EscPosCommands.setAlignment(0), [0x1B, 0x61, 0x00]);
      expect(EscPosCommands.setAlignment(1), [0x1B, 0x61, 0x01]);
      expect(EscPosCommands.setAlignment(2), [0x1B, 0x61, 0x02]);
    });

    test('alignment shortcuts work correctly', () {
      expect(EscPosCommands.alignLeft, [0x1B, 0x61, 0x00]);
      expect(EscPosCommands.alignCenter, [0x1B, 0x61, 0x01]);
      expect(EscPosCommands.alignRight, [0x1B, 0x61, 0x02]);
    });

    test('setBold returns correct bytes', () {
      expect(EscPosCommands.setBold(true), [0x1B, 0x45, 0x01]);
      expect(EscPosCommands.setBold(false), [0x1B, 0x45, 0x00]);
    });

    test('setUnderline returns correct bytes', () {
      expect(EscPosCommands.setUnderline(true), [0x1B, 0x2D, 0x01]);
      expect(EscPosCommands.setUnderline(false), [0x1B, 0x2D, 0x00]);
    });

    test('setCharacterSize clamps values correctly', () {
      // Normal size
      expect(EscPosCommands.setCharacterSize(width: 1, height: 1), [0x1D, 0x21, 0x00]);
      // Double width
      expect(EscPosCommands.setCharacterSize(width: 2, height: 1), [0x1D, 0x21, 0x10]);
      // Double height
      expect(EscPosCommands.setCharacterSize(width: 1, height: 2), [0x1D, 0x21, 0x01]);
      // Double both
      expect(EscPosCommands.setCharacterSize(width: 2, height: 2), [0x1D, 0x21, 0x11]);
    });

    test('encodeText encodes ASCII correctly', () {
      expect(EscPosCommands.encodeText('ABC'), [65, 66, 67]);
      expect(EscPosCommands.encodeText('123'), [49, 50, 51]);
    });

    test('printQrCode generates valid command sequence', () {
      final commands = EscPosCommands.printQrCode('TEST');
      
      // Should start with model select command
      expect(commands.sublist(0, 4), [0x1D, 0x28, 0x6B, 0x04]);
      
      // Should contain the data 'TEST'
      expect(commands.contains(84), isTrue); // 'T'
      expect(commands.contains(69), isTrue); // 'E'
      expect(commands.contains(83), isTrue); // 'S'
      
      // Should end with print command
      expect(commands.sublist(commands.length - 3), [0x31, 0x51, 0x30]);
    });
  });

  group('Sk58TextStyle', () {
    test('default style has no modifications', () {
      const style = Sk58TextStyle();
      expect(style.bold, isFalse);
      expect(style.underline, isFalse);
      expect(style.size, Sk58FontSize.normal);
    });

    test('preset styles are configured correctly', () {
      expect(Sk58TextStyle.boldStyle.bold, isTrue);
      expect(Sk58TextStyle.underlineStyle.underline, isTrue);
      expect(Sk58TextStyle.largeStyle.size, Sk58FontSize.large);
      expect(Sk58TextStyle.boldLarge.bold, isTrue);
      expect(Sk58TextStyle.boldLarge.size, Sk58FontSize.large);
    });

    test('copyWith creates new instance with modifications', () {
      const original = Sk58TextStyle();
      final modified = original.copyWith(bold: true);
      
      expect(original.bold, isFalse);
      expect(modified.bold, isTrue);
    });

    test('equality works correctly', () {
      const style1 = Sk58TextStyle(bold: true);
      const style2 = Sk58TextStyle(bold: true);
      const style3 = Sk58TextStyle(bold: false);
      
      expect(style1, equals(style2));
      expect(style1, isNot(equals(style3)));
    });
  });

  group('Sk58Align', () {
    test('alignment values are correct', () {
      expect(Sk58Align.left.value, 0);
      expect(Sk58Align.center.value, 1);
      expect(Sk58Align.right.value, 2);
    });
  });

  group('Sk58FontSize', () {
    test('font sizes have correct multipliers', () {
      expect(Sk58FontSize.normal.widthMultiplier, 1);
      expect(Sk58FontSize.normal.heightMultiplier, 1);
      
      expect(Sk58FontSize.wide.widthMultiplier, 2);
      expect(Sk58FontSize.wide.heightMultiplier, 1);
      
      expect(Sk58FontSize.tall.widthMultiplier, 1);
      expect(Sk58FontSize.tall.heightMultiplier, 2);
      
      expect(Sk58FontSize.large.widthMultiplier, 2);
      expect(Sk58FontSize.large.heightMultiplier, 2);
      
      expect(Sk58FontSize.extraLarge.widthMultiplier, 3);
      expect(Sk58FontSize.extraLarge.heightMultiplier, 3);
    });
  });

  group('Sk58Constants', () {
    test('UUIDs are valid format', () {
      expect(
        Sk58Constants.printerServiceUuid,
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')),
      );
      expect(
        Sk58Constants.printerCharacteristicUuid,
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')),
      );
    });

    test('chunk size is reasonable', () {
      expect(Sk58Constants.chunkSize, greaterThan(0));
      expect(Sk58Constants.chunkSize, lessThanOrEqualTo(512));
    });

    test('delays are positive', () {
      expect(Sk58Constants.chunkDelayMs, greaterThan(0));
      expect(Sk58Constants.defaultScanTimeoutSeconds, greaterThan(0));
      expect(Sk58Constants.connectionTimeoutSeconds, greaterThan(0));
    });
  });

  group('QrErrorCorrection', () {
    test('error correction levels have correct values', () {
      expect(QrErrorCorrection.L.value, 0x30);
      expect(QrErrorCorrection.M.value, 0x31);
      expect(QrErrorCorrection.Q.value, 0x32);
      expect(QrErrorCorrection.H.value, 0x33);
    });
  });
}
