import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class SongModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String path;
  @HiveField(2)
  String title;
  @HiveField(3)
  String artist;
  @HiveField(4)
  String? album;
  @HiveField(5)
  String? duration;
  @HiveField(6)
  String? artworkPath;

  SongModel({
    required this.id,
    required this.path,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.artworkPath,
  });

  SongModel copyWith({
    String? id,
    String? path,
    String? title,
    String? artist,
    String? album,
    String? duration,
    String? artworkPath,
  }) {
    return SongModel(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      artworkPath: artworkPath ?? this.artworkPath,
    );
  }
}
