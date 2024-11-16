// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Ghanti(),
    );
  }
}

class Ghanti extends StatefulWidget {
  const Ghanti({super.key});

  @override
  State<Ghanti> createState() => _GhantiState();
}

class _GhantiState extends State<Ghanti> {
  GyroscopeEvent? _gyroscopeEvent;

  int? _gyroscopeLastInterval;

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  Duration sensorInterval = SensorInterval.normalInterval;

  DateTime? _gyroscopeUpdateTime;

  static const Duration _ignoreDuration = Duration(milliseconds: 20);

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _streamSubscriptions.add(
      gyroscopeEvents.listen(
        (GyroscopeEvent event) {
          final now = DateTime.now();
          setState(() {
            _gyroscopeEvent = event;
            if (_gyroscopeUpdateTime != null) {
              final interval = now.difference(_gyroscopeUpdateTime!);
              if (interval > _ignoreDuration) {
                _gyroscopeLastInterval = interval.inMilliseconds;
              }
            }
          });
          _gyroscopeUpdateTime = now;

          if (_gyroscopeEvent!.x.abs() > 0.5 ||
              _gyroscopeEvent!.y.abs() > 0.5 ||
              _gyroscopeEvent!.z.abs() > 0.5) {
            _playSound();
          }
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Gyroscope Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
    loadAd();
  }

  @override
  void dispose() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound() async {
    await _audioPlayer.play(AssetSource('assets/notification.mp3'));
  }

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // paxi ad rakhna 
  final adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/xxx'
      : 'ca-app-pub-3940256099942544/xxx';

  /// banner ad load gaarna yehaaa
  void loadAd() {
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _isLoaded = true;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          // Dispose the ad here to free resources.
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghanti'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Ghanti'),
            if (_gyroscopeEvent != null)
              Transform(
                transform: Matrix4.rotationZ(_gyroscopeEvent!.z - 0.5),
                alignment: FractionalOffset.center,
                child: Image.network(
                  'https://cdn.discordapp.com/attachments/1267685646038859810/1267695433732325457/IMG_6560_Background_Removed.png?ex=66a9b8e0&is=66a86760&hm=05162ef5919e735dbb9de0aa6bf6e46e3898a57160882ab60294ad02c9b7a50d&',
                ),
              )
            else
              Image.network(
                'https://cdn.discordapp.com/attachments/1267685646038859810/1267695433732325457/IMG_6560_Background_Removed.png?ex=66a9b8e0&is=66a86760&hm=05162ef5919e735dbb9de0aa6bf6e46e3898a57160882ab60294ad02c9b7a50d&',
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Gyroscope'),
            ),
            Text(_gyroscopeEvent?.x.toStringAsFixed(1) ?? '?'),
            Text(_gyroscopeEvent?.y.toStringAsFixed(1) ?? '?'),
            Text(_gyroscopeEvent?.z.toStringAsFixed(1) ?? '?'),
            Text('${_gyroscopeLastInterval?.toString() ?? '?'} ms'),
            if (_bannerAd != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
