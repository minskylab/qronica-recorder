import 'dart:io' as io;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:qronica_recorder/local_storage.dart';
import 'package:qronica_recorder/pocketbase.dart';
import "package:http/http.dart";
import 'package:http_parser/http_parser.dart';
import 'package:qronica_recorder/session_storage.dart';

class StorageService {
  Position? position;

  Future<void> getCurrentPosition() async {
    Position currentPosition = await getLocationWithPermission();
    position = currentPosition;
  }

  Future<Position> getLocationWithPermission() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location Permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> uploadAudio(
    String path,
    String? duration,
    String fileName,
    List<String> projectIds,
  ) async {
    Uint8List uint8list = Uint8List(0);
    await getCurrentPosition();
    if (!kIsWeb) {
      File file = File(path);
      uint8list = await file.readAsBytes();
    }
    else{
      Uri myUri = Uri.parse(path);
      final Response responseData = await get(myUri);
      uint8list = responseData.bodyBytes;
    }
    print("Duracionnnn: $duration");

    String locationJSON = '''{
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "properties": {},
          "geometry": {
            "type": "Point",
            "coordinates": [
              ${position?.latitude},
              ${position?.longitude}
            ]
          }
        }
      ]
    }''';
    if (PocketBaseSample.client.authStore.isValid == false) {
      PocketBaseSample.client.authStore.save(
        LocalStorageHelper.getValue('token'),
        UserModel,
      );
    }
    final record = await PocketBaseSample.client.records.create(
      'resources',
      body: {
        'name': fileName,
        'kind': 'sound',
        'metadata': '''{"duration": "$duration" }''',
        'location': locationJSON,
        'creator': LocalStorageHelper.getValue('userId')
        //'projects': projectIds[0],
      },
      files: [
        MultipartFile.fromBytes(
          'file', // the name of the file field
          uint8list,
          filename: 'audio.webm',
          contentType: MediaType.parse('audio/webm'),
        )
      ],
    );
  }

  Future<List<RecordModel>> listFiles() async {
    final authData = await PocketBaseSample.client.users.authViaEmail(
      LocalStorageHelper.getValue('email'),
      LocalStorageHelper.getValue('password'),
    );

    final records = await PocketBaseSample.client.records.getFullList(
      'resources',
      batch: 200,
      sort: '-created',
    );

    return records;
  }

  Future<List<RecordModel>> listProjects() async {
    final authData = await PocketBaseSample.client.users.authViaEmail(
      LocalStorageHelper.getValue('email'),
      LocalStorageHelper.getValue('password'),
    );

    final projects = await PocketBaseSample.client.records.getFullList(
      'projects',
      batch: 200,
      sort: '-created',
    );

    return projects;
  }
}
