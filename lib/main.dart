import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late VoidCallback _listener;
  bool _isPlaying = false;
  late Timer _timer;
  Duration _currentPosition = Duration.zero;
  double _sliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/videos/naturesample.mp4',
    )..initialize().then((_) {
      setState(() {});
    });
    _listener = () {
      if (!_controller.value.isPlaying &&
          _controller.value.isInitialized) {
        setState(() {
          _isPlaying = false;
        });
      } else if (_controller.value.isPlaying && _isPlaying == false) {
        setState(() {
          _isPlaying = true;
        });
      }
    };
    _controller.addListener(_listener);

    // Setup a timer to update the running time every second
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (_controller.value.isPlaying) {
        setState(() {
          _currentPosition =
              _controller.value.position;
          _sliderValue = _currentPosition.inMilliseconds /
              _controller.value.duration.inMilliseconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void _seekRelative(int seconds) {
    final newPosition =
        _controller.value.position + Duration(seconds: seconds);
    if (newPosition.inMilliseconds < 0) {
      _controller.seekTo(Duration.zero);
    } else if (newPosition.inMilliseconds >
        _controller.value.duration.inMilliseconds) {
      _controller.seekTo(_controller.value.duration);
    } else {
      _controller.seekTo(newPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
      ),
      body: Stack(
        children: [
          _controller.value.isInitialized
              ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
              : CircularProgressIndicator(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${formatDuration(_currentPosition)}',
                        style: TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: Slider(
                          value: _sliderValue,
                          onChanged: (value) {
                            setState(() {
                              _sliderValue = value;
                              final newPosition = Duration(
                                milliseconds: (value *
                                    _controller
                                        .value.duration.inMilliseconds)
                                    .round(),
                              );
                              _controller.seekTo(newPosition);
                            });
                          },
                          activeColor: Colors.green[200],
                        ),
                      ),
                      Text(
                        '${formatDuration(_controller.value.duration)}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.skip_previous, color: Colors.white),
                        onPressed: () {
                          _seekRelative(-5);
                        },
                      ),
                      IconButton(
                        icon: _isPlaying
                            ? Icon(Icons.pause, color: Colors.white)
                            : Icon(Icons.play_arrow, color: Colors.white),
                        onPressed: () {
                          _isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_next, color: Colors.white),
                        onPressed: () {
                          _seekRelative(5);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatDuration(Duration duration) {
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
