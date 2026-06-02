enum SongErrorType {
  syncFailed,
  loadFailed,
  addSongsFailed,
  countFailed,
  unknown,
}

enum PlaybackStatus { initial, loading, playing, paused, stopped, failure }

enum SongChangeType { upsert, delete }
