import 'dart:io' as io;
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  Position? position;
  final firebase_storage.FirebaseStorage storage = 
  firebase_storage.FirebaseStorage.instance;

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
  ) async {
    await getCurrentPosition();
    print(position);
    Uri myUri = Uri.parse(path);
    final http.Response responseData = await http.get(myUri);
    final uint8list = responseData.bodyBytes;
    final user = FirebaseAuth.instance.currentUser;
    final db = FirebaseFirestore.instance;
    DateTime now = DateTime.now();
    final timestamp = '${now.hour}:${now.minute}:${now.second}.${now.millisecond}';
    try {
      await storage.ref('test/$fileName').putData(uint8list);
    } on firebase_core.FirebaseException catch (e)
    {
      print(e);
    }

    await db.collection('records').add({
    'uid': user!.uid, 
    'email': user.email,
    'location': position.toString(), 
    'timestamp': timestamp,
    'audio': fileName, 
    }).then((value){
      print('Record added');
    }).catchError((dynamic error) => print('Failed to add: $error')); 

  }

  Future<firebase_storage.ListResult> listFiles() async {
    firebase_storage.ListResult results = await storage.ref('test').listAll();

    results.items.forEach((firebase_storage.Reference ref) { 
      print("Found file: $ref");
    });
    return results;
  }

  Future<String> downloadUrl(String fileName) async {
    String downloadUrl = await storage.ref('test/$fileName').getDownloadURL();

    return downloadUrl;
  }

}