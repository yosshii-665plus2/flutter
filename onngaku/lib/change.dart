import 'dart:typed_data';
import 'package:ongaku/main.dart';

enum Change_type {
  pich,
  tone,
  move,
}

class Change{
  Change_type change;
  double quantity;

  Change({required this.change,this.quantity=0});

  static String log( String logdata){
    print("log: $logdata");
    return "";
  }
  Map<String,dynamic> toJson()
  {
    return {
      'change':(){
        String type;
        switch(change){
        case Change_type.pich:type='pich';break;
        case Change_type.tone:type='tone';break;
        case Change_type.move:type='move';break;
        }
        return type;
      }(),
      'quantity':quantity
    };
  }
  
  static Float32List pushToFloat32List(HakeiState hakei,List<Change> changes){
    Float32List newFloat32List=hakei.pcm;
    for(Change _change in changes)
    {
      switch(_change.change){
        case Change_type.pich:_change_pich(hakei);break;
        case Change_type.tone:break;
        case Change_type.move:break;
      }
    }
    return Float32List.fromList([]);
  }
  
  static HakeiState _change_pich(HakeiState hakei)
  {
    HakeiState newhakei =hakei;
    List<List<HakeiState>> Portioning=[];


    return newhakei;
  }
}