/*
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'package:saytarly/core/database/db_helper.dart';

class LocalApiServer {
  HttpServer? _server;

  Future<void> start() async {
    final router = Router();

    router.get('/ping', (Request request) {
      return Response.ok('OK');
    });

    router.get('/menu', (Request request) async {
      final db = await DBHelper.database;

      final drinks = await db.query(
        'drinks',
        where: "temperature NOT IN ('cigarette')",
      );

      return Response.ok(
        jsonEncode(drinks),
        headers: {'Content-Type': 'application/json'},
      );
    });

    router.post('/order', (Request request) async {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      await DBHelper.createOrder(
        tableId: data['tableId'],
        tableName: data['tableName'],
        note: data['note'],
        items: List<Map<String, dynamic>>.from(data['items']),
      );

      return Response.ok(
        jsonEncode({"success": true}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    _server = await io.serve(
      router.call,
      InternetAddress.anyIPv4,
      5000,
    );

    print(
      'SERVER STARTED http://${_server!.address.address}:${_server!.port}',
    );
  }
}
*/
