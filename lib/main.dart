import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/dance_viewmodel.dart';
import 'views/welcome_view.dart';
import 'views/card_swipe_view.dart';
import 'views/people_gallery_view.dart';
import 'package:audio_session/audio_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up audio session to allow background music from other apps (like Spotify/Apple Music)
  // to continue playing while this app runs.
  final session = await AudioSession.instance;
  await session.configure(
    const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.ambient,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.sonification,
        flags: AndroidAudioFlags.audibilityEnforced,
        usage: AndroidAudioUsage.notification,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: true,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => DanceViewModel(),
      child: const VoyeurApp(),
    ),
  );
}

class VoyeurApp extends StatelessWidget {
  const VoyeurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voyeur',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainContainer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainContainer extends StatelessWidget {
  const MainContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DanceViewModel>(context);

    return Scaffold(backgroundColor: Colors.black, body: _buildBody(viewModel));
  }

  Widget _buildBody(DanceViewModel viewModel) {
    switch (viewModel.appState) {
      case AppState.welcome:
        return WelcomeView();
      case AppState.loading:
        return _buildLoading(viewModel.statusMessage);
      case AppState.browsing:
        return const CardSwipeView();
      case AppState.gallery:
        return const PeopleGalleryView();
      case AppState.error:
        return _buildError(viewModel);
    }
  }

  Widget _buildLoading(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.blue),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildError(DanceViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            const Text(
              "Error Occurred",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              viewModel.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => viewModel.reload(),
              child: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }
}
