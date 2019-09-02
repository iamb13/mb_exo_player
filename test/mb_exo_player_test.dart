import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mb_exo_player/mb_exo_player.dart';

void main() {
  const MethodChannel channel = MethodChannel('mb_exo_player');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

//  test('getPlatformVersion', () async {
//    expect(await MbExoPlayer.platformVersion, '42');
//  });
}
