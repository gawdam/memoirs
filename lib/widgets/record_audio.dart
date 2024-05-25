import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'audio_controller.dart'; // Import the controller logic

class RecordAudio extends StatefulWidget {
  const RecordAudio({super.key});

  @override
  _RecordAudioState createState() => _RecordAudioState();
}

class _RecordAudioState extends State<RecordAudio> {
  final AudioController _audioController = AudioController();

  @override
  void initState() {
    super.initState();
    _audioController.initializeControllers();
    _audioController.getDir().then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _audioController.disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Builder(builder: (context) {
            var duration =
                _audioController.getDuration().toString().substring(2, 7);
            return Text(
              "$duration",
              style: TextStyle(
                  fontSize: 24,
                  color:
                      _audioController.isEnhanced ? Colors.teal : Colors.blue),
            );
          }),
          _audioController.isEnhancementDone
              ? Switch(
                  value: _audioController.isEnhanced,
                  onChanged: (bool value) {
                    setState(() {
                      _audioController.toggleEnhancer(value);
                    });
                  },
                  activeColor: Colors.red,
                )
              : Text("Waiting for enhancement"),
          SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1000),
            child: Builder(builder: (context) {
              switch (_audioController.recordingState) {
                case RecordingState.idle:
                  return Text("Start Recording!");
                case RecordingState.recording:
                  return AudioWaveforms(
                    key: ValueKey('recorder'),
                    enableGesture: true,
                    size: Size(MediaQuery.of(context).size.width, 300),
                    recorderController: _audioController.recorderController,
                    waveStyle: const WaveStyle(
                      waveColor: Color.fromARGB(255, 0, 0, 0),
                      showDurationLabel: true,
                      extendWaveform: true,
                      showMiddleLine: true,
                      scaleFactor: 100,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                  );
                default:
                  return AudioFileWaveforms(
                    // key: ValueKey(_audioController.isEnhanced),
                    size: Size(MediaQuery.of(context).size.width, 150),
                    playerController: _audioController.playerController,
                    playerWaveStyle: PlayerWaveStyle(
                      fixedWaveColor: Colors.grey,
                      liveWaveColor: _audioController.isEnhanced
                          ? Colors.teal
                          : Colors.blue,
                      spacing: 4,
                      showSeekLine: true,
                      scaleFactor: 200,
                      seekLineColor: Colors.red,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                  );
              }
            }),
          ),
          SizedBox(height: 40),
          Builder(builder: (context) {
            switch (_audioController.recordingState) {
              case RecordingState.idle:
                return ElevatedButton(
                  onPressed: _audioController.startRecording,
                  child: const Icon(Icons.mic),
                );
              case RecordingState.recording:
                return ElevatedButton(
                  onPressed: _audioController.stopRecording,
                  child: const Icon(Icons.stop),
                );
              case RecordingState.recordingComplete:
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _audioController.startPlayer();
                        });
                      },
                      child: const Icon(Icons.play_arrow),
                    ),
                    SizedBox(width: 20),
                    !_audioController.isEnhancementDone
                        ? ElevatedButton(
                            onPressed: () {
                              _audioController.uploadRecording().then((_) {
                                setState(() {});
                              });
                            },
                            child: const Icon(Icons.upload),
                          )
                        : Container(),
                  ],
                );
              default:
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _audioController.pausePlayer();
                        });
                      },
                      child: const Icon(Icons.pause),
                    ),
                    SizedBox(width: 20),
                    !_audioController.isEnhancementDone
                        ? ElevatedButton(
                            onPressed: () {
                              _audioController.uploadRecording().then((_) {
                                setState(() {});
                              });
                            },
                            child: const Icon(Icons.upload),
                          )
                        : Container(),
                  ],
                );
            }
          }),
        ],
      ),
    );
  }
}
