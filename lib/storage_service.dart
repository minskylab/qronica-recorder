import 'dart:io' as io;
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final firebase_storage.FirebaseStorage storage = 
  firebase_storage.FirebaseStorage.instance;

  Future<void> uploadAudio(
    String path,
    String fileName,
  ) async {
    Uri myUri = Uri.parse(path);
    final http.Response responseData = await http.get(myUri);
    final uint8list = responseData.bodyBytes;

    try {
      await storage.ref('test/$fileName').putData(uint8list);
    } on firebase_core.FirebaseException catch (e)
    {
      print(e);
    }
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