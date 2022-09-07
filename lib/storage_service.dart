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

class StorageService {
  Position? position;

  Future<void> getCurrentPosition() async {
    Position currentposition = await getLocationwithPermission();
    position = currentposition;
  }

  Future<Position> getLocationwithPermission() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
    {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location Permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

  }

  Future<void> uploadAudio(
    String path,
    String fileName,
    int duration,
  ) async {
    await getCurrentPosition();
    Uri myUri = Uri.parse(path);
    final http.Response responseData = await http.get(myUri);
    final uint8list = responseData.bodyBytes;
    if (PocketBaseSample.client.authStore.isValid == false)
    {
      PocketBaseSample.client.authStore.save(LocalStorageHelper.getValue('token')!, UserModel);
    }
    final record = await PocketBaseSample.client.records.create('records', 
    body: {
    'user': LocalStorageHelper.getValue('userId'),
    'location': position.toString(),
    'duration' : duration
    },
    files:[
      http.MultipartFile.fromBytes(
        'audio', // the name of the file field
        uint8list,
        filename: 'audio.blob',
      )
    ],
    );
  }

  Future<List<RecordModel>> listFiles() async {
    final records = await PocketBaseSample.client.records.getFullList('records', batch: 200, sort: '-created');
    print(records);
    return records;
  }
  Stream<RecordModel?> getRecord() async* {
    late RecordModel? prueba;
    final client = PocketBase('http://127.0.0.1:8090');
    client.users.authViaEmail('ju@li.com', 'julian29');
    client.realtime.subscribe('records', (e) {
    print(e.record);
    prueba = e.record;
    });
    yield prueba;
  }



}