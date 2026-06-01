import 'dart:io';

String getMusicDirectory() {
  final home = Platform.environment['HOME'] ?? '/home';
  return '$home/Music';
}
