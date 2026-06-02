import 'dart:io';

import 'package:mechanix_music/core/utils/enums.dart';
import 'package:mechanix_music/l10n/music_localizations.dart';

String getMusicDirectory() {
  final home = Platform.environment['HOME'] ?? '/home';
  return '$home/Music';
}

String songErrorMessage(AppLocalizations l10n, SongErrorType errorType) {
  return switch (errorType) {
    SongErrorType.syncFailed => l10n.errorSyncFailed,
    SongErrorType.loadFailed => l10n.errorLoadFailed,
    SongErrorType.addSongsFailed => l10n.errorAddSongsFailed,
    SongErrorType.countFailed => l10n.errorCountFailed,
    SongErrorType.unknown => l10n.errorUnknown,
  };
}
