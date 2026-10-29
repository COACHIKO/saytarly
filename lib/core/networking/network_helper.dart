import 'dart:convert';

import 'package:http/http.dart' as http;

import '../services/shared_pref/pref_keys.dart';
import '../services/shared_pref/shared_pref.dart';

class NetworkAPICall {
  var token = SharedPref.sharedPreferences.getString(PrefKeys.accessToken);

  postDataAsGuest(data, apiUrl) async {
    return await http.post(Uri.parse(apiUrl), body: jsonEncode(data), headers: {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    }).timeout(
      Duration(seconds: 5),
      onTimeout: () {
        return http.Response('Error Time out', 408);
      },
    );
  }

  getData(apiUrl) async {
    token = SharedPref.sharedPreferences.getString(PrefKeys.accessToken);
    return await http.get(Uri.parse(apiUrl), headers: _setHeaders()).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        return http.Response('Error Time out', 408);
      },
    );
  }

  getDataWithoutTimout(apiUrl) async {
    token = SharedPref.sharedPreferences.getString("token");
    return await http.get(Uri.parse(apiUrl), headers: _setHeaders());
  }

  Future<http.Response> getDataAsGuest(String baseUrl,
      {Map<String, dynamic>? params}) async {
    print("params from network: " + params.toString());
    // Construct the full URL with parameters
    var uri = Uri.parse(baseUrl);
    if (params != null) {
      uri = uri.replace(queryParameters: params);
    }

    return await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    }).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        // Timeout handling logic
        return http.Response('Error Time out', 408);
      },
    );
  }

  addData(data, apiUrl) async {
    token = SharedPref.sharedPreferences.getString(PrefKeys.accessToken);
    return await http
        .post(Uri.parse(apiUrl), body: jsonEncode(data), headers: _setHeaders())
        .timeout(
      Duration(seconds: 5),
      onTimeout: () {
        return http.Response('Error Time out', 408);
      },
    );
  }

  editData(data, apiUrl) async {
    token = SharedPref.sharedPreferences.getString(PrefKeys.accessToken);
    return await http
        .put(Uri.parse(apiUrl), body: jsonEncode(data), headers: _setHeaders())
        .timeout(
      Duration(seconds: 5),
      onTimeout: () {
        return http.Response('Error Time out', 408);
      },
    );
  }

  deleteData(apiUrl) async {
    token = SharedPref.sharedPreferences.getString(PrefKeys.accessToken);

    return await http.delete(Uri.parse(apiUrl), headers: _setHeaders()).timeout(
      Duration(seconds: 5),
      onTimeout: () {
        return http.Response('Error Time out', 408);
      },
    );
  }

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      };
}
