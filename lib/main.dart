import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

const double boxSize = 80;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TapBox(),
    );
  }
}

class TapBox extends StatefulWidget {
  const TapBox({super.key});

  @override
  State<TapBox> createState() => _TapBoxState();
}

class Boxes extends StatefulWidget {
  final double top;
  final double left;
  final bool shin;
  final VoidCallback onExpire; // タイムアウトしたときに親へ知らせる連絡係

  const Boxes({
    super.key,
    required this.top,
    required this.left,
    required this.onExpire,
    this.shin = false,
  });

  @override
  State<Boxes> createState() => _BoxesState();
}

class _BoxesState extends State<Boxes> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 10秒後に1回だけ発火（periodicではなくTimerでOK）
    _timer = Timer(const Duration(seconds: 10), () {
      widget.onExpire(); // 親(TapBox)に「時間切れになった」と連絡する
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // タップされて先に消えた場合、発火しないように止める（超重要）
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ここではPositionedを持たない。Positionedは呼び出し側（_TapBoxState）で
    // Stackの直接の子として付ける必要があるので、ここではただの見た目だけ返す。
    return Container(
      width: boxSize,
      height: boxSize,
      color: Colors.orange,
    );
  }
}

class _TapBoxState extends State<TapBox> {
  final List<Boxes> boxlist = [];
  final Random _random = Random();
  int counta = 0;

  @override
  void initState() {
    super.initState();
    // 最初の1マスを、画面サイズが確定したあとのフレームで配置する
    WidgetsBinding.instance.addPostFrameCallback((_) {
      how_boxes(MediaQuery.of(context).size);
    });
  }

  // タップ or タイムアウトでマスを1個消す共通処理
  void _removeBox(Boxes box) {
    if (!mounted) return;
    setState(() {
      if (box.shin) counta = 0; // 本物を見逃したら最初からやり直し
      boxlist.remove(box);
    });
  }

  // ランダムな位置のマスを1個作る（onExpireの中で自分自身を参照するのでlateを使う）
  Boxes _makeBox(double top, double left, {bool shin = false}) {
    late Boxes box;
    box = Boxes(
      top: top,
      left: left,
      shin: shin,
      onExpire: () => _removeBox(box),
    );
    return box;
  }

  void how_boxes(Size gamenSize) {
    final List<Boxes> tmp = [];
    double randomTop = 0;
    double randomLeft = 0;

    for (int i = 0; i < counta; i++) {
      randomTop = _random.nextDouble() * (gamenSize.height - boxSize);
      randomLeft = _random.nextDouble() * (gamenSize.width - boxSize);
      tmp.add(_makeBox(randomTop, randomLeft));
    }

    if (counta == 0) {
      tmp.add(_makeBox(
        gamenSize.height / 2 - boxSize / 2,
        gamenSize.width / 2 - boxSize / 2,
        shin: true,
      ));
    } else {
      randomTop = _random.nextDouble() * (gamenSize.height - boxSize);
      randomLeft = _random.nextDouble() * (gamenSize.width - boxSize);
      tmp.add(_makeBox(randomTop, randomLeft, shin: true));
    }

    setState(() {
      counta++;
      boxlist
        ..clear()
        ..addAll(tmp);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          for (final info in boxlist)
            Positioned(
              // ← Positionedがここ、Stackの直接の子になった
              top: info.top,
              left: info.left,
              child: GestureDetector(
                key: ObjectKey(info), // リストの中身が入れ替わってもStateを正しく対応させる
                onTap: () {
                  if (!info.shin) {
                    _removeBox(info);
                  } else {
                    how_boxes(screenSize);
                  }
                },
                child: info,
              ),
            ),
        ],
      ),
    );
  }
}