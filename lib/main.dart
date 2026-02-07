import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape orientation for better gameplay
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system UI for immersive experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const AbyssRunnerApp());
}

class AbyssRunnerApp extends StatelessWidget {
  const AbyssRunnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abyss Runner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const GameScreen(),
    );
  }
}
