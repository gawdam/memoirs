import 'dart:io';
import 'dart:math';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:memoirs/services/denoise_api.dart';
import 'package:path_provider/path_provider.dart';

enum RecordingState { idle, recording, recordingComplete, playing }

class RecordAudio extends StatefulWidget {
  const RecordAudio({super.key});

  @override
  State<StatefulWidget> createState() {
    return _RecordAudioState();
  }
}

class _RecordAudioState extends State<RecordAudio> {
  late final RecorderController recorderController;
  late final PlayerController playerController = PlayerController();
  late final PlayerController enhancedController = PlayerController();

  String? path;
  String? enhancedPath;
  String? musicFile;

  bool isEnhanced = false;
  bool isEnhancementDone = false;

  var recordingState = RecordingState.idle;

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
    enhancedPath = "${appDirectory.path}/enhanced.m4a";
    setState(() {});
  }

  void _initialiseControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
  }

  void _stopRecording() async {
    recorderController.reset();
    path = await recorderController.stop(false);
    if (path != null) {
      playerController.dispose();
      //Add media to player waveform
      await playerController.preparePlayer(
        path: path!,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1,
      );
    }
  }

  void _startRecording() async {
    await recorderController.record(path: path);
  }

  void _uploadRecording() async {
    Denoise denoise = Denoise(mediaPath: path, enhancedPath: enhancedPath);
    await denoise.getAPIToken();
    print("Done");
    await denoise.uploadAudio();
    await denoise.enhanceAudio();
    // await Future.delayed(const Duration(seconds: 5));
    int progress = 0;
    while (progress < 100) {
      progress = await denoise.checkJobStatus();
      print('Current progress: $progress%');

      await Future.delayed(Duration(seconds: 1));
    }
    await denoise.saveEnhancedAudio();
    enhancedController.dispose();
    await enhancedController.preparePlayer(
      path: enhancedPath!,
      shouldExtractWaveform: true,
      noOfSamples: 100,
      volume: 1,
    );
    setState(() {
      isEnhancementDone = true;
    });
  }

  void _discardRecording() {
    recorderController.stop();
    recorderController.reset();

    // recorderController.refresh();
    // recorderController.record(path: path);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            isEnhancementDone
                ? Switch(
                    value: isEnhanced,
                    onChanged: (bool value) {
                      setState(() {
                        isEnhanced = value;
                      });
                    },
                    activeColor: Colors.red,
                  )
                : Text("Waiting for enhancement"),
            SizedBox(
              height: 20,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              child: Builder(builder: (context) {
                switch (recordingState) {
                  case RecordingState.idle:
                    return Text("Start Recording!");

                  case RecordingState.recording:
                    return AudioWaveforms(
                      enableGesture: true,
                      size: Size(MediaQuery.of(context).size.width, 200),
                      recorderController: recorderController,
                      waveStyle: const WaveStyle(
                          waveColor: Color.fromARGB(255, 0, 0, 0),
                          extendWaveform: true,
                          showMiddleLine: true,
                          scaleFactor: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                    );

                  default:
                    if (isEnhanced) {
                      return AudioFileWaveforms(
                        size: Size(MediaQuery.of(context).size.width, 200),
                        waveformType: WaveformType.fitWidth,
                        playerController: enhancedController,
                        playerWaveStyle: const PlayerWaveStyle(
                            fixedWaveColor: Colors.grey,
                            liveWaveColor: Colors.teal,
                            spacing: 4,
                            showSeekLine: true,
                            scaleFactor: 200,
                            seekLineColor: Colors.red),
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                      );
                    } else {
                      return AudioFileWaveforms(
                        size: Size(MediaQuery.of(context).size.width, 200),
                        waveformType: WaveformType.fitWidth,
                        playerController: playerController,
                        playerWaveStyle: const PlayerWaveStyle(
                            fixedWaveColor: Colors.grey,
                            liveWaveColor: Colors.teal,
                            spacing: 4,
                            showSeekLine: true,
                            scaleFactor: 200,
                            seekLineColor: Colors.red),
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                      );
                    }
                }
              }),
            ),
            SizedBox(
              height: 40,
            ),
            Builder(builder: (context) {
              switch (recordingState) {
                case RecordingState.idle:
                  return ElevatedButton(
                      onPressed: () {
                        _startRecording();
                        setState(() {
                          recordingState = RecordingState.recording;
                        });
                      },
                      child: const Icon(Icons.mic));

                case RecordingState.recording:
                  return ElevatedButton(
                      onPressed: () {
                        _stopRecording();
                        setState(() {
                          recordingState = RecordingState.recordingComplete;
                        });
                      },
                      child: const Icon(Icons.stop));

                case RecordingState.recordingComplete:
                  return ElevatedButton(
                      onPressed: () {
                        if (!isEnhanced) {
                          playerController.startPlayer(
                              finishMode: FinishMode.loop);
                        } else {
                          enhancedController.startPlayer(
                              finishMode: FinishMode.loop);
                        }
                        setState(() {
                          recordingState = RecordingState.playing;
                        });
                      },
                      child: const Icon(Icons.play_arrow));

                case RecordingState.playing:
                  return ElevatedButton(
                      onPressed: () {
                        if (!isEnhanced) {
                          playerController.pausePlayer();
                        } else {
                          enhancedController.pausePlayer();
                        }
                        setState(() {
                          recordingState = RecordingState.recordingComplete;
                        });
                      },
                      child: const Icon(Icons.pause));
              }
            }),
            ElevatedButton(
                onPressed: () {
                  _uploadRecording();
                },
                child: const Icon(Icons.upload)),
            // Builder(builder: (context) {
            //   if (isEnhanced) {
            //     return Column(
            //       children: [
            //         AudioFileWaveforms(
            //           size: Size(MediaQuery.of(context).size.width, 150),
            //           waveformType: WaveformType.fitWidth,
            //           playerController: enhancedController,
            //           playerWaveStyle: const PlayerWaveStyle(
            //               fixedWaveColor: Colors.grey,
            //               liveWaveColor: Colors.teal,
            //               spacing: 4,
            //               showSeekLine: true,
            //               scaleFactor: 200,
            //               seekLineColor: Colors.red),
            //           margin: const EdgeInsets.symmetric(horizontal: 15),
            //         ),
            //         ElevatedButton(
            //             onPressed: () {
            //               enhancedController.startPlayer(
            //                   finishMode: FinishMode.loop);
            //             },
            //             child: const Icon(Icons.play_arrow))
            //       ],
            //     );
            //   }
            //   return Text("Not initialized");
            // })
          ]),
    );
  }
}
