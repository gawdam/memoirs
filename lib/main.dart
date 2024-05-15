import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:memoirs/screens/home.dart';

RecorderController controller = RecorderController();
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          // colorScheme:
          //     ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 2, 1, 3)),
          // useMaterial3: true,
          ),
      home: const MyHomePage(title: 'Memoirs'),
    );
  }
}
