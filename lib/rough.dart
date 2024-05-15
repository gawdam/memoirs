import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final RecorderController recorderController;
  String? path;
  String? musicFile;
  bool isRecording = false;
  bool isRecordingCompleted = false;
  bool isLoading = true;
  late Directory appDirectory;

  @override
  void initState() {
    super.initState();
    _getDir();
    _initialiseControllers();
  }

  void _getDir() async {
    appDirectory = await getApplicationDocumentsDirectory();
    path = "${appDirectory.path}/recording.m4a";
    isLoading = false;
    setState(() {});
  }

  void _initialiseControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      musicFile = result.files.single.path;
      setState(() {});
    } else {
      debugPrint("File not picked");
    }
  }

  void _startOrStopRecording() async {
    try {
      if (isRecording) {
        recorderController.reset();

        path = await recorderController.stop(false);

        if (path != null) {
          isRecordingCompleted = true;
          debugPrint(path);
          debugPrint("Recorded file size: ${File(path!).lengthSync()}");
        }
      } else {
        await recorderController.record(path: path); // Path is optional
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isRecording = !isRecording;
      });
    }
  }

  void _refreshWave() {
    if (isRecording) {
      debugPrint("Refresg");

      recorderController.stop();
      recorderController.refresh();
      recorderController.record(path: path);

      // _startOrStopRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
          child: Row(children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 1000),
          child: isRecording
              ? AudioWaveforms(
                  enableGesture: true,
                  size: Size(MediaQuery.of(context).size.width / 2, 50),
                  recorderController: recorderController,
                  waveStyle: const WaveStyle(
                    waveColor: Color.fromARGB(255, 255, 255, 255),
                    extendWaveform: true,
                    showMiddleLine: true,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Color.fromARGB(255, 12, 12, 12),
                  ),
                  padding: const EdgeInsets.only(left: 18),
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                )
              : Container(
                  width: MediaQuery.of(context).size.width / 1.7,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 0, 0, 0),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.only(left: 18),
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: "Type Something...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      contentPadding: const EdgeInsets.only(top: 16),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        onPressed: _pickFile,
                        icon: Icon(Icons.adaptive.share),
                        color: Color.fromARGB(136, 255, 255, 255),
                      ),
                    ),
                  ),
                ),
        ),
        IconButton(
          onPressed: _refreshWave,
          icon: Icon(
            isRecording ? Icons.refresh : Icons.send,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: _startOrStopRecording,
          icon: Icon(isRecording ? Icons.stop : Icons.mic),
          color: const Color.fromARGB(255, 0, 0, 0),
          iconSize: 28,
        ),
      ])),
    );
  }
}
