import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Denoise {
  Denoise({required this.mediaPath, required this.enhancedPath});

  final mediaPath;
  final enhancedPath;
  late String jobID;
  late String apiToken;
  late String auth;

  Future<void> getAPIToken() async {
    await dotenv.load(fileName: '.env');
    auth = base64Encode(
        utf8.encode('${dotenv.env['APP_KEY']}:${dotenv.env['APP_SECRET']}'));
    debugPrint(auth);
    debugPrint('-----------------');
    var headers = {
      'Authorization': 'Basic $auth',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    var data = 'grant_type=client_credentials&expires_in=1800';

    var url = Uri.parse('https://api.dolby.io/v1/auth/token');
    var res = await http.post(url, headers: headers, body: data);
    if (res.statusCode != 200)
      throw Exception('http.post error: statusCode= ${res.statusCode}');
    apiToken = json.decode(res.body)['access_token'];
  }

  //----------------------------------------------------------------------------------------------
  Future<void> uploadAudio() async {
    var headers = {
      'Authorization': 'Bearer $apiToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    var data = '{"url": "dlb://memoirs/denoise.m4a"}';
    var url = Uri.parse('https://api.dolby.com/media/input');

    try {
      final response = await http.post(url, headers: headers, body: data);

      if (response.statusCode == 200) {
        print('Upload $mediaPath to ${response.body}');

        final uploadConfig = {
          'method': 'put',
          'url': json.decode(response.body)['url'],
          'headers': {
            'Content-Type': 'application/octet-stream',
            'Content-Length': File(mediaPath!).lengthSync().toString(),
          },
          'body': File(mediaPath).readAsBytesSync(),
        };

        final uploadResponse = await http.put(
          Uri.parse(uploadConfig['url'].toString()),
          headers: uploadConfig['headers'] as Map<String, String>,
          body: uploadConfig['body'],
        );

        if (uploadResponse.statusCode == 200) {
          print('File uploaded');
        } else {
          print('Error uploading file: ${uploadResponse.statusCode}');
        }
      } else {
        print('Error getting upload URL: ${response.statusCode}');
        print("");
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> enhanceAudio() async {
    var headers = {
      'Authorization': 'Bearer $apiToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    var data = {
      "input": "dlb://memoirs/denoise.m4a",
      "output": "dlb://memoirs/enhanced.m4a",
      "content": {"type": "mobile_phone"},
      "audio": {
        "noise": {
          "reduction": {"amount": "max"}
        },
        // "dynamics": {
        //   "range_control": {"enable": false}
        // },
        // "speech": {
        //   "sibilance": {
        //     "reduction": {"enable": false}
        //   },
        //   "isolation": {"enable": true, "amount": 100}
        // },
        // "dynamics": {
        //   "range_control": {"enable": false}
        // },
      }
    };

    var url = Uri.parse('https://api.dolby.com/media/enhance');
    var res = await http.post(url, headers: headers, body: json.encode(data));
    if (res.statusCode != 200)
      throw Exception('http.post error: statusCode= ${res.statusCode}');
    jobID = json.decode(res.body)['job_id'];
    print(jobID);
  }

  Future<int> checkJobStatus() async {
    var headers = {
      'Authorization': 'Bearer $apiToken',
    };

    var url = Uri.parse('https://api.dolby.com/media/enhance?job_id=$jobID');
    var res = await http.get(url, headers: headers);
    if (res.statusCode != 200)
      throw Exception('http.get error: statusCode= ${res.statusCode}');
    var progress = json.decode(res.body)['progress'] as int;
    return progress;
  }

  Future<void> saveEnhancedAudio() async {
    final url = Uri.parse(
        'https://api.dolby.com/media/output?url=dlb://memoirs/enhanced.m4a');
    final headers = {
      'Authorization': 'Bearer $apiToken',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final file = File(enhancedPath);
        await file.writeAsBytes(response.bodyBytes);
        print('File downloaded successfully to $enhancedPath');
      } else {
        print('Failed to download file: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
