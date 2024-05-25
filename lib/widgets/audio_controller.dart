import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:memoirs/services/denoise_api.dart';
import 'package:path_provider/path_provider.dart';

enum RecordingState { idle, recording, recordingComplete, playing }

class AudioController {
  late final RecorderController recorderController;
  late final PlayerController playerController;

  String? path;
  String? enhancedPath;

  bool isEnhanced = false;
  bool isEnhancementDone = false;

  RecordingState recordingState = RecordingState.idle;

  late Directory appDirectory;

  int currentDuration = 0;

  void initializeControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;

    playerController = PlayerController();
  }

  Future<void> getDir() async {
    appDirectory = await getApplicationDocumentsDirectory();
    path = "${appDirectory.path}/recording.m4a";
    enhancedPath = "${appDirectory.path}/enhanced.m4a";
  }

  Future<void> startRecording() async {
    await recorderController.record(path: path);
    recordingState = RecordingState.recording;
  }

  Future<void> stopRecording() async {
    recorderController.reset();
    path = await recorderController.stop(false);
    if (path != null) {
      await playerController.preparePlayer(
        path: path!,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1,
      );
    }
    recordingState = RecordingState.recordingComplete;
  }

  Future<void> uploadRecording() async {
    Denoise denoise = Denoise(mediaPath: path, enhancedPath: enhancedPath);
    await denoise.getAPIToken();
    await denoise.uploadAudio();
    await denoise.enhanceAudio();

    int progress = 0;
    while (progress < 100) {
      progress = await denoise.checkJobStatus();
      print('Current progress: $progress%');
      await Future.delayed(Duration(seconds: 1));
    }

    await denoise.saveEnhancedAudio();

    isEnhancementDone = true;
  }

  void toggleEnhancer(bool value) {
    isEnhanced = value;
    recordingState = RecordingState.recordingComplete;

    if (isEnhanced && enhancedPath != null) {
      playerController.release();
      playerController.stopPlayer();
      playerController.seekTo(0);

      playerController.preparePlayer(
        path: enhancedPath!,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1,
      );
    } else if (!isEnhanced && path != null) {
      playerController.release();
      playerController.stopPlayer();
      playerController.seekTo(0);

      playerController.preparePlayer(
        path: path!,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1,
      );
    }
  }

  Duration getDuration() {
    playerController.onCurrentDurationChanged.listen((duration) {
      currentDuration = duration;
    });
    return Duration(milliseconds: currentDuration);
  }

  void startPlayer() {
    playerController.startPlayer(finishMode: FinishMode.loop);
    recordingState = RecordingState.playing;
  }

  void pausePlayer() {
    playerController.pausePlayer();
    recordingState = RecordingState.recordingComplete;
  }

  void disposeControllers() {
    recorderController.dispose();
    playerController.dispose();
  }
}
