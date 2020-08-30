import 'package:flutter/material.dart';
import 'package:ruz/constants.dart';
import 'package:ruz/ruz.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectPage extends StatelessWidget {
  final notes;
  String get date => notes['date'];
  String get beginTime => notes['beginTime'];
  String get endTime => notes['endTime'];
  String get discipline => notes['discipline'];
  String get lessonType => notes['lessonType'];
  String get auditorium => notes['auditorium'];
  String get location => notes['location'];
  String get teacher => notes['teacher'];
  String get disciplineId => notes['disciplineId'];
  const SubjectPage({@required this.notes});

  @override
  Widget build(BuildContext context) {
    String lessonPlace = '$lessonType, ';
    lessonPlace += auditorium == 'Удалённо' ? auditorium : 'ауд. $auditorium';

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context))),
        body: CustomScrollView(
          slivers: <Widget>[
            SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              flex: 7,
                              child: Text(lessonPlace,
                                  maxLines: 2,
                                  style: TextStyle(
                                    color: getAppointmentColor(lessonType),
                                    fontSize: 18,
                                  )),
                            ),
                            Flexible(
                              flex: 2,
                              child: Text(date),
                            ),
                          ]),
                      SizedBox(height: 10),
                      Text(discipline,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600)),
                      Divider(thickness: 1.5, color: Colors.black, height: 30),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Flexible(
                            flex: 2,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    beginTime,
                                    style: settingsMidRowStyle,
                                  ),
                                  Icon(Icons.keyboard_arrow_down, size: 25),
                                  Text(endTime, style: settingsMidRowStyle),
                                ]),
                          ),
                          Spacer(flex: 1),
                          Flexible(
                              flex: 9,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(teacher, style: settingsMidRowStyle),
                                  SizedBox(height: 25),
                                  Text(location, style: settingsMidRowStyle),
                                ],
                              ))
                        ],
                      ),
                      Divider(color: Colors.black, height: 30),
                      Row(
                        children: <Widget>[
                          Spacer(),
                          InkWell(
                            child: Container(
                              padding: EdgeInsets.all(8),
                              child: Text('О дисциплине',
                                  style: settingsMidRowStyle.copyWith(
                                    color: Colors.blueAccent,
                                  )),
                            ),
                            onTap: () async {
                              var resHashMap =
                                  await getSubjectURL(disciplineId);
                              Map<String, Map> res = Map.from(resHashMap);
                              String url = res[res.keys.toList()[0]]['url'];
                              launch(url);
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
