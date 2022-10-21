import 'dart:io' as io;
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:qronica_recorder/local_storage.dart';
import 'package:qronica_recorder/pocketbase.dart';
import 'package:universal_html/html.dart';

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
    String fileName,
    int duration,
    List<String> projectIds,
  ) async {
    await getCurrentPosition();
    Uri myUri = Uri.parse(path);
    final http.Response responseData = await http.get(myUri);
    final uint8list = responseData.bodyBytes;
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
        'metadata': '''{"duration": $duration}''',
        'location': locationJSON,
        'creator': LocalStorageHelper.getValue('userId')
        //'projects': projectIds[0],
      },
      files: [
        http.MultipartFile.fromBytes(
          'file', // the name of the file field
          uint8list,
          filename: 'audio.blob',
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
