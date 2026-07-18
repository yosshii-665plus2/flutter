import 'dart:math';
import 'dart:async'; // Timerを使うために必要
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: TapBox(), 
        ),
      ),
    );
  }
}

class TapBox extends StatefulWidget {
  const TapBox({super.key});

  // 「俺の本当の本体（State）は、下の『_TapBoxState』だよ」とFlutterに教えている
  @override
  State<TapBox> createState() => _TapBoxState();
}

class Boxes extends StatefulWidget{
  final double top;
  final double left;
  final bool shin;
  const Boxes({super.key,required this.top,required this.left,this.shin=false});

  State<Boxes> createState() => _BoxesState();
} 

class _BoxesState extends State<Boxes>
{
  Timer? _timer;
  void startTimer() {
    // 1秒ごとに {} の中身を実行するタイマーを起動！
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        if(widget.shin)counta=0;
        boxlist.remove(this);
      });
    });
  }
  
  @override
  void initState() {
    super.initState();
    // 画面が組み立てられた（誕生した）瞬間に、自動で関数を実行する！
    startTimer(); 
  }

  @override
  Widget build(BuildContext context) {
    return Positioned( 
      top: widget.top,
      left: widget.left,
      child:Container(
        width: 80, 
        height: 80,
        color: Colors.orange
      )
    );
  }
}



class _TapBoxState extends State<TapBox> {
  List<Boxes> boxlist=[];
  Random _random = Random();
  int counta=0;

  void how_boxes(Size gamenSize)
  {
    List<Boxes> _boxlist_tmp=[];
    int _i=0;
    double _random_top=0;
    double _random_left=0;
    while(true)
    {
      double boxsize=80;
      _random_top=_random.nextDouble()*(gamenSize.height-boxsize);
      _random_left=_random.nextDouble()*(gamenSize.width-boxsize);

      if(_i>=counta){break;}
      _boxlist_tmp.add(Boxes(top: _random_top, left: _random_left));
      _i++;
    }
      if(counta==0){_boxlist_tmp.add(Boxes(top: gamenSize.height/2-40, left: gamenSize.width/2-40));}
      else _boxlist_tmp.add(Boxes(top: _random_top, left: _random_left,shin: true));
    setState(() {
      counta++;
      boxlist=_boxlist_tmp;  
    });
  }
  
    @override
    Widget build(BuildContext context) {
      final Size screenSize = MediaQuery.of(context).size;
      return Scaffold(
        body: Stack(
          children: [
            for(var info in boxlist)
            GestureDetector(
              onTap: () {
                info.shin==false
                ?setState(() {boxlist.remove(info);})
                :how_boxes(screenSize);
              },
              child:info
              
            )
          ],
        ),
      ) ;
      

    }
  }