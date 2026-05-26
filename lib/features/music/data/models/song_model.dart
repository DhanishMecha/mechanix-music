import 'package:objectbox/objectbox.dart';

@Entity()
class SongModel {
  @Id()
  int obxId; // ObjectBox internal ID

  @Unique()
  @Index()
  String id;
  
  @Unique()
  @Index()
  String path;

  String title;
  String artist;
  String? album;
  String? duration;
  String? artworkPath;

  SongModel({
    this.obxId = 0,
    required this.id,
    required this.path,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.artworkPath,
  });
}
