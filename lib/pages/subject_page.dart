import 'package:flutter/material.dart';
import 'package:ruz/constants.dart';
import 'package:ruz/ruz.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectPage extends StatelessWidget {
  final notes;
  String get date => notes['date'];
  String get beginLesson => notes['beginLesson'];
  String get endLesson => notes['endLesson'];
  String get discipline => notes['discipline'];
  String get kindOfWork => notes['kindOfWork'];
  String get auditorium => notes['auditorium'];
  String get building => notes['building'];
  String get lecturer => notes['lecturer'];
  String get disciplineinplan => notes['disciplineinplan'];
  String get url1 => notes['url1'];
  String get group => notes['group'];

  const SubjectPage({@required this.notes});

  @override
  Widget build(BuildContext context) {
    String lessonPlace = '$kindOfWork, ';
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
                  child: getMainBody(
                    lessonPlace: lessonPlace,
                    kindOfWork: kindOfWork,
                    date: date,
                    discipline: discipline,
                    beginLesson: beginLesson,
                    endLesson: endLesson,
                    lecturer: lecturer,
                    building: building,
                    disciplineinplan: disciplineinplan,
                    url1: url1,
                    group: group,
                  ),
                ))
          ],
        ),
      ),
    );
  }
}

Widget getMainBody({
  @required lessonPlace,
  @required kindOfWork,
  @required date,
  @required discipline,
  @required beginLesson,
  @required endLesson,
  @required lecturer,
  @required building,
  @required disciplineinplan,
  @required url1,
  @required group,
}) {
  var mainColumn = <Widget>[
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(
        flex: 7,
        child: Text(lessonPlace,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: getAppointmentColor(kindOfWork),
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
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
    Divider(thickness: 1.5, color: Colors.black, height: 30),
    Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Flexible(
          flex: 2,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  beginLesson,
                  style: settingsMidRowStyle,
                ),
                Icon(Icons.keyboard_arrow_down, size: 25),
                Text(endLesson, style: settingsMidRowStyle),
              ]),
        ),
        Spacer(flex: 1),
        Flexible(
            flex: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(lecturer, style: settingsMidRowStyle),
                SizedBox(height: 25),
                Text(building, style: settingsMidRowStyle),
              ],
            ))
      ],
    ),
    SizedBox(height: 10),
    Divider(color: Colors.black, height: 15),
    ListTile(
      contentPadding: EdgeInsets.all(0),
      leading: Icon(Icons.group, color: Colors.black54),
      title: Text(group,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: settingsMidRowStyle.copyWith(fontSize: 15)),
    )
  ];

  if (url1 != null) {
    mainColumn.addAll([
      Divider(height: 10, color: Colors.black),
      ListTile(
        contentPadding: EdgeInsets.all(0),
        onTap: () => launch(url1),
        leading: Icon(Icons.link, color: Colors.black54),
        title: Text(url1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: settingsMidRowStyle.copyWith(
              color: Colors.blueAccent,
            )),
      )
    ]);
  }

  mainColumn.addAll([
    Divider(color: Colors.black, height: 20),
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
            var resHashMap = await getSubjectURL(disciplineinplan);
            Map<String, Map> res = Map.from(resHashMap);
            String url = res[res.keys.toList()[0]]['url'];
            launch(url);
          },
        ),
      ],
    ),
  ]);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: mainColumn,
  );
}
