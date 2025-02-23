import 'package:flutter/cupertino.dart';

import '../../../domain/models/dict/dict.dart';
import 'package:dict_reader/dict_reader.dart';

class DictViewModel extends ChangeNotifier {
  Map<String, (int, int, int, int)>? mdict;
  late final DictReader dictReader;
  MDictModel? dictvm;
  var queryResult = '';
  var filePath = '';

  void query(String word) async {
    print(word.trim());
    filePath = '';
    if (dictvm == null) {
      dictvm = MDictModel(filePath);
      mdict = await dictvm!.getMdict();
    }
    // print('gfff:');
    // print(mdict.map['underwear']);
    // for (final key in mdict!.keys) {
    //   print('gfff: $key');
    // }

    final offset = mdict!["underwear"];
    // print(offset);
    queryResult = await dictvm!.dictReader
        .readOne(offset!.$1, offset.$2, offset.$3, offset.$4);

    print(queryResult);

    notifyListeners();
  }
}
