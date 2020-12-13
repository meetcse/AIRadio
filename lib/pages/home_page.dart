import 'dart:math';

import 'package:airadio/model/radio.dart';
import 'package:airadio/utils/ai_util.dart';
import 'package:alan_voice/alan_voice.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocity_x/velocity_x.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MyRadio> radios;
  MyRadio _selectedRadio;
  Color _selectedColor;
  bool _isPlaying = false;

  final _suggestions = [
    "Play",
    "Play some music",
    "Play the music",
    "Stop",
    "Pause music",
    "Play rock music",
    "Play 98.3 fm",
    "Play next",
    "Pause",
    "Play previous",
    "Play pop music",
    "Play 102 fm",
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    // TODO: implement initState
    setUpAlan();
    super.initState();
    fetchRadios();
    _audioPlayer.onPlayerStateChanged.listen((event) {
      if (event == AudioPlayerState.PLAYING) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
      }

      setState(() {});
    });
  }

  setUpAlan() {
    AlanVoice.addButton(
      "eed89d9146ab40c7281ab91658f9b7b52e956eca572e1d8b807a3e2338fdd0dc/stage",
      buttonAlign: AlanVoice.BUTTON_ALIGN_RIGHT,
    );
    AlanVoice.callbacks.add((command) {
      _handleCommand(command.data);
    });
  }

  _handleCommand(Map<String, dynamic> response) {
    switch (response['command']) {
      case 'play':
        print("IN PLAY...");
        _playMusic(_selectedRadio.url);

        break;

      case 'stop':
        _audioPlayer.stop();
        break;

      case 'next':
        final index = _selectedRadio.id;
        MyRadio _newRadio;
        if (index + 1 > radios.length) {
          _newRadio = radios.firstWhere((element) => element.id == 1);
          radios.remove(_newRadio);
          radios.insert(0, _newRadio);
        } else {
          _newRadio = radios.firstWhere((element) => element.id == index + 1);
          radios.remove(_newRadio);
          radios.insert(0, _newRadio);
        }
        _selectedColor = Color(int.tryParse(_newRadio.color));
        _playMusic(_newRadio.url);
        break;

      case 'prev':
        final index = _selectedRadio.id;
        MyRadio _newRadio;
        if (index - 1 <= 0) {
          _newRadio = radios.last;
          radios.remove(_newRadio);
          radios.insert(0, _newRadio);
        } else {
          _newRadio = radios.firstWhere((element) => element.id == index - 1);
          radios.remove(_newRadio);
          radios.insert(0, _newRadio);
        }
        _selectedColor = Color(int.tryParse(_newRadio.color));

        _playMusic(_newRadio.url);
        break;

      case 'play_channel':
        final _id = response['id'];
        _audioPlayer.pause();
        MyRadio _newRadio;

        _newRadio = radios.firstWhere((element) => element.id == _id);
        radios.remove(_newRadio);
        radios.insert(0, _newRadio);

        _selectedColor = Color(int.tryParse(_newRadio.color));

        _playMusic(_newRadio.url);

        break;

      default:
        print("Command ${response['command']}");
        break;
    }
  }

  fetchRadios() async {
    final radioJson = await rootBundle.loadString('assets/radio.json');
    radios = MyRadioList.fromJson(radioJson).radios;
    _selectedRadio = radios[new Random.secure().nextInt(radios.length)];
    print("Radios :" + radios.toString());
    setState(() {});
  }

  //To play music
  _playMusic(String url) {
    _audioPlayer.play(url);
    _selectedRadio = radios.firstWhere((element) => element.url == url);
    print("SELECTED RADIO : " + _selectedRadio.name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SafeArea(
        top: false,
        child: Drawer(
          child: Container(
            color: _selectedColor ?? AIColors.primaryColor2,
            child: radios != null
                ? [
                    80.heightBox,
                    "All Channels".text.xl.white.semiBold.make().px16(),
                    20.heightBox,
                    ListView(
                            padding: Vx.m0,
                            shrinkWrap: true,
                            children: radios
                                .map(
                                  (e) => ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage(e.icon),
                                    ),
                                    title: "${e.name} FM".text.white.make(),
                                    subtitle: e.tagline.text.white.make(),
                                  ),
                                )
                                .toList())
                        .expand(),
                  ].vStack(crossAlignment: CrossAxisAlignment.start)
                : const Offstage(),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          VxAnimatedBox()
              .size(context.screenWidth, context.screenHeight)
              .withGradient(LinearGradient(
                colors: [
                  AIColors.primaryColor2,
                  _selectedColor ?? AIColors.primaryColor1,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ))
              .make(),
          [
            AppBar(
              title: "AI Radio".text.xl4.bold.white.make().shimmer(
                    primaryColor: Vx.purple300,
                    secondaryColor: Colors.white,
                  ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ).h(100).p16(),

            "Start with - Hey Alan👇".text.semiBold.italic.white.make(),
            10.heightBox,

            //Building suggestions
            VxSwiper.builder(
                itemCount: _suggestions.length,
                // viewportFraction: 0.28,
                height: 50,
                autoPlay: true,
                autoPlayInterval: 2.seconds,
                autoPlayAnimationDuration: 400.milliseconds,
                autoPlayCurve: Curves.easeInOutQuad,
                enableInfiniteScroll: true,
                itemBuilder: (context, index) {
                  final s = _suggestions[index];
                  return Chip(
                      label: s.text.make(), backgroundColor: Vx.randomColor);
                }),
          ].vStack(),
          30.heightBox,
          //Creating Swiping Radio UI
          radios == null
              ? Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.white,
                  ),
                )
              : VxSwiper.builder(
                  enlargeCenterPage: true,
                  itemCount: radios.length,
                  onPageChanged: (index) {
                    final colorHex = radios[index].color;
                    _selectedColor = Color(int.tryParse(colorHex));
                    setState(() {});
                  },
                  aspectRatio: context.mdWindowSize == MobileWindowSize.xsmall
                      ? 1.0
                      : context.mdWindowSize == MobileWindowSize.medium
                          ? 2.0
                          : 3.0,
                  itemBuilder: (context, index) {
                    final rad = radios[index];
                    return VxBox(
                      child: ZStack(
                        [
                          Positioned(
                            top: 0.0,
                            right: 0.0,
                            child: VxBox(
                              child: rad.category.text.uppercase.white
                                  .make()
                                  .px16(),
                            )
                                .height(40)
                                .withRounded(value: 10)
                                .black
                                .alignCenter
                                .make(),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: VStack(
                              [
                                rad.name.text.xl3.white.bold.make(),
                                5.heightBox,
                                rad.tagline.text.semiBold.sm.white.make(),
                              ],
                              crossAlignment: CrossAxisAlignment.center,
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: [
                              Icon(
                                _isPlaying
                                    ? CupertinoIcons.stop_circle
                                    : CupertinoIcons.play_circle,
                                color: Colors.white,
                              ),
                              10.heightBox,
                              _isPlaying
                                  ? "Double Tap to stop".text.gray300.make()
                                  : "Double Tap to play".text.gray300.make(),
                            ].vStack(),
                          ),
                        ],
                      ),
                    )
                        .clip(Clip.antiAlias)
                        .bgImage(
                          DecorationImage(
                            image: NetworkImage(rad.image),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.3),
                              BlendMode.darken,
                            ),
                          ),
                        )
                        .withRounded(value: 60)
                        .border(color: Colors.black, width: 5.0)
                        .make()
                        .onInkDoubleTap(() {
                      if (_isPlaying) {
                        _audioPlayer.stop();
                      } else {
                        _playMusic(rad.url);
                      }
                    }).p16();
                  }).centered(),
          //Icon at bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: [
              if (_isPlaying)
                "PLAYING NOW - ${_selectedRadio.name} FM"
                    .text
                    .white
                    .makeCentered(),
              Icon(
                _isPlaying
                    ? CupertinoIcons.stop_circle
                    : CupertinoIcons.play_circle,
                color: Colors.white,
                size: 50,
              ).onInkTap(() {
                _isPlaying
                    ? _audioPlayer.stop()
                    : _playMusic(_selectedRadio.url);
              }),
            ].vStack(),
          ).pOnly(bottom: context.percentHeight * 10),
        ],
      ),
    );
  }
}
