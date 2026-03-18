class AppConfig {
  static const String apiBaseURL = "https://peoplesystem.tatdvsonorth.com/tymg";
  static const String resourceBaseURL = "https://peoplesystem.tatdvsonorth.com";

  static String get peopleImageBaseURL => "$resourceBaseURL/images/people";
  
  static final List<String> gangVideoUrls = [
    '$peopleImageBaseURL/gangHagisun.mp4',
    '$peopleImageBaseURL/gangHagishi.mp4',
    '$peopleImageBaseURL/gangPhoenix.mp4',
    '$peopleImageBaseURL/gangRegalos.mp4',
    '$peopleImageBaseURL/gangRapeum.mp4',
  ];
}
