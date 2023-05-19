import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const List<String> additionalKeywords = [
  'bitcoin mining',
  'bitcoin energy',
  'bitcoin inflation',
  'digibyte',
  'reddcoin',
  'decred',
  'pivx',
  'particl',
  'stakenet',
  'paycoin',
];

Future<Response> getKeyWordHandler(Request request) async {
  final botId = request.params['botid']!;
  final cmcData = await getCMCData();
  List keywordPool = [...additionalKeywords];

  for (final coin in cmcData) {
    keywordPool.add(coin["name"]);
  }
  keywordPool.shuffle();

  final topFiveFromPool = keywordPool.sublist(0, 5);
  final topFiveFromDB = await getTopFiveKeyWords(botId);

  final aggregatedKeyWordPool = [...topFiveFromDB, ...topFiveFromPool];
  aggregatedKeyWordPool.toSet().toList(); //filter duplicates
  aggregatedKeyWordPool.shuffle();
  return Response.ok(aggregatedKeyWordPool.elementAt(0));
}

Future<List<dynamic>> getCMCData() async {
  var response = await http.get(
    Uri(
      scheme: 'https',
      host: 'pro-api.coinmarketcap.com',
      path: 'v1/cryptocurrency/map',
      query: 'start=1&limit=20&sort=cmc_rank',
    ),
    headers: {
      'accept': 'application/json',
      'X-CMC_PRO_API_KEY': Platform.environment['CMC_API_KEY']!,
    },
  );
  return json.decode(response.body)["data"];
}

Future<List<String>> getTopFiveKeyWords(String botId) async {
  final conn = await MySQLConnection.createConnection(
    host: Platform.environment['MYSQL_HOST']!,
    port: int.parse(Platform.environment['MYSQL_PORT']!),
    userName: Platform.environment['MYSQL_USER']!,
    password: Platform.environment['MYSQL_PASSWORD']!,
    databaseName: Platform.environment['MYSQL_DB']!,
  );

  await conn.connect();

  var resultList = <String>[];
  var result = await conn.execute(
      "SELECT keyword, COUNT(keyword) FROM follows WHERE followedBack = '1' AND bot = $botId AND (keyword IS NOT NULL AND keyword != '') GROUP BY keyword ORDER BY Count(keyword) DESC LIMIT 5");
  for (final row in result.rows) {
    resultList.add(row.colByName('keyword')!);
  }

  await conn.close();

  return resultList;
}
