void main() {
  // 1. 画面に文字を出力する
  print('Hello, Dart World!');
  
  // 2. 変数（データを一時保存する箱）
  var appName = 'おもしろアプリ'; // 自動で文字列(String)と判定される
  int version = 1;              // 整数(int)を明示して指定
  
  // 3. 文字列の中に変数を埋め込む（$マークを使う）
  print('開発中のアプリ: $appName (Ver.$version)');
  
  // 4. 簡単な条件分岐
  if (version < 5) {
    print('まだまだ開発は始まったばかり！');
  } else {
    print('かなりベテランアプリですね！');
  }
}