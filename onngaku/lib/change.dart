import 'dart:typed_data';

import 'package:ongaku/main.dart';

class Changes{
  static String log({dynamic logdata}){
    print("Changes.log() called");
    return "";
  }
  
  static Float32List pushToFloat32List(HakeiState hakei,List<Changes> changes){

    return Float32List.fromList([]);
  }
}