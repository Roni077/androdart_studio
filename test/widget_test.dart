import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:androdart_studio/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const prootChannel = MethodChannel(
    'com.androdartstudio.flutteride.androdart_studio/proot',
  );
  const ptyChannel = MethodChannel(
    'com.androdartstudio.flutteride.androdart_studio/pty',
  );
  const ptyOutputChannel = MethodChannel(
    'com.androdartstudio.flutteride.androdart_studio/pty_output',
  );
  const ptyExitChannel = MethodChannel(
    'com.androdartstudio.flutteride.androdart_studio/pty_exit',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(prootChannel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getNativeLibDir':
          return '/mock/native';
        case 'getFilesDir':
          return '/mock/files';
        default:
          return null;
      }
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ptyChannel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'create':
          return 1;
        case 'write':
        case 'resize':
        case 'close':
          return null;
        default:
          return null;
      }
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            ptyOutputChannel, (MethodCall methodCall) async {
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            ptyExitChannel, (MethodCall methodCall) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(prootChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ptyChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ptyOutputChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ptyExitChannel, null);
  });

  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Pump multiple frames to let FutureBuilder resolve
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
