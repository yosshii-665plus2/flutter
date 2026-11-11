import 'package:ongaku/change.dart';
import 'package:ongaku/main.dart';
import 'audio_utils.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class HakeiToFile {
  static Future<String> hakeiToFile(dynamic hakeiData) async{
    if(hakeiData == null){
      return "";
    }
    String newfilepath="";
    if(hakeiData is PickupState||hakeiData is Rean){
      Float32List float32List=hakeiData is PickupState?Changes.pushToFloat32List(hakeiData.hakeistate, hakeiData.changes):hakeiData.combiningRean();
      Uint8List _audioBytes=Uint8List.fromList(float32List.buffer.asUint8List(float32List.offsetInBytes,float32List.lengthInBytes,),);
      if()
      {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/temp_audio.wav');
        await file.writeAsBytes(_audioBytes);
        newfilepath=file.path;
      }
    }else{print("error:hakeitofile datatype");}

    return newfilepath;
  }
}