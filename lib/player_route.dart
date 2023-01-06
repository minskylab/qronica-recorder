import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/src/dtos/record_model.dart';
import 'package:qronica_recorder/audio_player.dart';
import 'package:qronica_recorder/pocketbase.dart';


class PlayerRoute extends StatelessWidget {
  const PlayerRoute(
    {Key? key, required this.snapshot}) : super(key: key);

  final RecordModel snapshot;
  
  @override
  Widget build(BuildContext context) {
        final List<String?> _path = [
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
  ];
    DateTime now = DateTime.now();
    String formattedDateNow = DateFormat('yyyy-MM-dd').format(now);
    DateTime recordDate =  DateTime.parse(snapshot.created);
    String formattedRecordDate = DateFormat('yyyy-MM-dd').format(recordDate);
    String time = DateFormat.Hm().format(recordDate);
    return Scaffold(
    appBar: AppBar(
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Padding(
            padding: EdgeInsets.only(left: 16),
            child:  Text(
              snapshot.data['name'],
              style: TextStyle(
                color: Color(0XFF1E1E1E),
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ),
      body: Container(
        padding: EdgeInsets.only(top: 40, left: 24, right:24),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              snapshot.data['name'],
              style: Theme.of(context).textTheme.bodyText1?.merge(
                const TextStyle(
                  fontWeight: FontWeight.w700, 
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 12,),
            Row(
              children: [
                Text(
                  "Titulo del proyecto",
                  style: Theme.of(context).textTheme.bodyText1?.merge(
                    const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "",
                  style: Theme.of(context).textTheme.bodyText1?.merge(
                    const TextStyle(
                      fontWeight: FontWeight.w500, 
                      fontSize: 14,
                    ),
                  ),
                )
              ],
            ),
            SizedBox(height: 12,),
            Row(
              children: [
                Text(
                  formattedDateNow == formattedRecordDate ?
                  "Grabado a las $time" :
                  "Grabado, $formattedRecordDate a las $time",
                  style: Theme.of(context).textTheme.bodyText1?.merge(
                    const TextStyle(
                      fontWeight: FontWeight.w500, 
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "",
                  style: Theme.of(context).textTheme.bodyText1?.merge(
                    const TextStyle(
                      fontWeight: FontWeight.w500, 
                      fontSize: 14,
                    ),
                  ),
                )
              ],
            ),
            Row(
              children: [
                Text(
                  "",
                  style: Theme.of(context).textTheme.bodyText1?.merge(
                    const TextStyle(
                      fontWeight: FontWeight.w500, 
                      fontSize: 12,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  "Duracion de ${snapshot.data['metadata']['duration']}",
                  style: Theme.of(context).textTheme.bodyText1?.merge(
                    const TextStyle(
                      fontWeight: FontWeight.w500, 
                      fontSize: 12,
                    ),
                  ),
                )
              ],
            ),
            AudioPlayer(
              path: _path,
              sourceType: 'onlineAudio',
              onlinePath: '${PocketBaseSample.url}/api/files/resources/${snapshot.id}/${snapshot.data['file']}',)
          ],
        )
      ),
    );
  }
}