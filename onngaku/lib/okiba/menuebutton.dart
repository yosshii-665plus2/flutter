import 'package:flutter/material.dart';

class Menuebutton  extends StatelessWidget{
  final Future<void> Function() pickAndProcess;
  const Menuebutton({
    super.key,
    required this.pickAndProcess
    });
  @override
  Widget build(BuildContext context){
      return PopupMenuButton<String>(
      // 見た目をボタン風にカスタマイズ
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu, color: Colors.white),
              SizedBox(width: 8),
              Text('メニュー', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        // メニュー項目が選択されたときの処理
        onSelected: (String value) {
          if (value == 'select_file') {
          pickAndProcess();
          } else if (value == 'other_option') {
          // 別の処理
          }
        },
        // ドロップダウンの中身
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
            value: 'select_file',
            child: Row(
              children: [
                Icon(Icons.folder_open, color: Colors.black87),
                SizedBox(width: 8),
                Text('音声ファイルを選択'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'other_option',
            child: Row(
              children: [
                Icon(Icons.settings, color: Colors.black87),
                SizedBox(width: 8),
                Text('設定'),
              ],
            ),
          ),
        ],
      );
  }    
}