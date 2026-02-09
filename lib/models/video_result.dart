class VideoResult {
  final String personName;
  final String url;
  final String filename;

  VideoResult({
    required this.personName,
    required this.url,
    required this.filename,
  });

  String get id => url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoResult &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}
