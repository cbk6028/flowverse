import 'package:dict_reader/dict_reader.dart';

class MDict {
  final map = <String, (int, int, int, int)>{};

  MDict(map);
  // final offset = map["underwear"];
  //   print(await dictReader.readOne(offset!.$1, offset.$2, offset.$3, offset.$4));
}

class MDictModel {
  late final DictReader dictReader;

  MDictModel(String filePath) {
    dictReader = DictReader(filePath);
  }

  Future<Map<String, (int, int, int, int)>> getMdict() async {
    await dictReader.init();

    final map = <String, (int, int, int, int)>{};
    await for (final (keyText, offset) in dictReader.read()) {
      // print(keyText);
      map[keyText] = offset;
    }
    print('hh');
    // for (final key in map.keys) {
    //   print(key);
    // }
    return map;
  }

  // Implement or remove the query method if not needed
  // Future<void> query(int offset) {
  //   // Implementation here
  // }
}
