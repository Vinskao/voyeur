import 'person.dart';

class VideoResult {
  final String personName;
  final String url;
  final String filename;
  final Person? person; // Link to person data for sorting

  VideoResult({
    required this.personName,
    required this.url,
    required this.filename,
    this.person,
  });

  String get id => url;

  VideoResult copyWith({Person? person}) {
    return VideoResult(
      personName: personName,
      url: url,
      filename: filename,
      person: person ?? this.person,
    );
  }

  Map<String, dynamic> toJson() => {
    'personName': personName,
    'url': url,
    'filename': filename,
  };

  factory VideoResult.fromJson(Map<String, dynamic> json) {
    return VideoResult(
      personName: json['personName'] as String,
      url: json['url'] as String,
      filename: json['filename'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoResult &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}
