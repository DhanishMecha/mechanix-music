import 'package:equatable/equatable.dart';

sealed class SongEvent extends Equatable {
  const SongEvent();

  @override
  List<Object?> get props => [];
}

final class SongInitialized extends SongEvent {
  const SongInitialized();
}

final class SongLoadMore extends SongEvent {
  const SongLoadMore();
}
