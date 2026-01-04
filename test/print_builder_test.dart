import 'package:flutter_test/flutter_test.dart';
import 'package:sk58_printer/sk58_printer.dart';

void main() {
  group('Sk58PrintBuilder', () {
    late List<int> executedCommands;
    late Sk58PrintBuilder builder;

    setUp(() {
      executedCommands = [];
      builder = Sk58PrintBuilder((commands) async {
        executedCommands = commands;
      });
    });

    test('starts with empty commands', () {
      expect(builder.getCommands(), isEmpty);
    });

    test('text adds text command', () {
      builder.text('Hello');

      final commands = builder.getCommands();
      expect(commands, containsAllInOrder('Hello'.codeUnits));
      expect(commands, contains(0x0A)); // Line feed
    });

    test('text with style applies bold', () {
      builder.text('Bold', style: Sk58TextStyle.boldStyle);

      final commands = builder.getCommands();
      // ESC E 1 (bold on)
      expect(commands, containsAllInOrder([0x1B, 0x45, 1]));
      // ESC E 0 (bold off)
      expect(commands, containsAllInOrder([0x1B, 0x45, 0]));
    });

    test('text with alignment sets alignment', () {
      builder.text('Center', align: Sk58Align.center);

      final commands = builder.getCommands();
      // ESC a 1 (center)
      expect(commands, containsAllInOrder([0x1B, 0x61, 1]));
    });

    test('bold adds bold text', () {
      builder.bold('Bold text');

      final commands = builder.getCommands();
      expect(commands, containsAllInOrder([0x1B, 0x45, 1])); // Bold on
      expect(commands, containsAllInOrder('Bold text'.codeUnits));
    });

    test('header adds large centered bold text', () {
      builder.header('TITLE');

      final commands = builder.getCommands();
      // Should have center alignment
      expect(commands, containsAllInOrder([0x1B, 0x61, 1]));
      // Should have bold
      expect(commands, containsAllInOrder([0x1B, 0x45, 1]));
      // Should have text
      expect(commands, containsAllInOrder('TITLE'.codeUnits));
    });

    test('qrCode adds QR code commands', () {
      builder.qrCode('DATA');

      final commands = builder.getCommands();
      // GS ( k commands
      expect(commands, contains(0x1D)); // GS
      expect(commands, contains(0x28)); // (
      expect(commands, contains(0x6B)); // k
    });

    test('barcode adds barcode commands', () {
      builder.barcode('ABC123', type: BarcodeType.code128);

      final commands = builder.getCommands();
      // GS k commands
      expect(commands, contains(0x1D)); // GS
      expect(commands, contains(0x6B)); // k
      expect(commands, contains(73)); // Code128 type
    });

    test('line adds horizontal line', () {
      builder.line(width: 16, char: '-');

      final commands = builder.getCommands();
      // 16 dashes
      final dashes = List.filled(16, 0x2D);
      expect(commands, containsAllInOrder(dashes));
    });

    test('doubleLine adds double line', () {
      builder.doubleLine(width: 10);

      final commands = builder.getCommands();
      // 10 equals signs
      final equals = List.filled(10, 0x3D);
      expect(commands, containsAllInOrder(equals));
    });

    test('feed adds line feeds', () {
      builder.feed(5);

      final commands = builder.getCommands();
      final feeds = commands.where((c) => c == 0x0A).length;
      expect(feeds, 5);
    });

    test('newLine adds single line feed', () {
      builder.newLine();

      final commands = builder.getCommands();
      expect(commands, [0x0A]);
    });

    test('align sets alignment', () {
      builder.align(Sk58Align.right);

      final commands = builder.getCommands();
      expect(commands, containsAllInOrder([0x1B, 0x61, 2])); // Right
    });

    test('raw adds raw commands', () {
      builder.raw([0x1B, 0x40]); // Initialize

      final commands = builder.getCommands();
      expect(commands, containsAllInOrder([0x1B, 0x40]));
    });

    test('row formats two-column text', () {
      builder.row('Item', '\$10');

      final commands = builder.getCommands();
      expect(commands, containsAllInOrder('Item'.codeUnits));
      expect(commands, containsAllInOrder('\$10'.codeUnits));
    });

    test('chaining works correctly', () {
      builder
          .header('RECEIPT')
          .line()
          .text('Item 1')
          .row('Total', '\$10')
          .feed(3);

      final commands = builder.getCommands();
      expect(commands, isNotEmpty);
      expect(commands, containsAllInOrder('RECEIPT'.codeUnits));
      expect(commands, containsAllInOrder('Item 1'.codeUnits));
      expect(commands, containsAllInOrder('Total'.codeUnits));
    });

    test('execute calls executor', () async {
      builder.text('Test');

      await builder.execute();

      expect(executedCommands, isNotEmpty);
      expect(executedCommands, containsAllInOrder('Test'.codeUnits));
    });

    test('execute with empty commands does nothing', () async {
      await builder.execute();

      expect(executedCommands, isEmpty);
    });

    test('clear removes all commands', () {
      builder.text('Test');
      expect(builder.getCommands(), isNotEmpty);

      builder.clear();
      expect(builder.getCommands(), isEmpty);
    });

    test('getCommands returns unmodifiable list', () {
      builder.text('Test');
      final commands = builder.getCommands();

      expect(() => (commands as List).add(0xFF), throwsUnsupportedError);
    });
  });
}
