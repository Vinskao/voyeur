import 'person.dart';
import 'video_result.dart';

class CharacterVideos {
  final Person person;
  final List<VideoResult> videos;

  CharacterVideos({required this.person, required this.videos});

  String get name => person.name;
}
