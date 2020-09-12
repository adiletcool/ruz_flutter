import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ruz/constants.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../ruz.dart';
import 'search.dart';
import 'package:ruz/main.dart' show MyCalendar, DataSource;
import 'package:intl/intl.dart';

import 'subject_page.dart';

class OtherSchedule extends StatefulWidget {
  final Obj object;
  final String type;
  const OtherSchedule(this.object, this.type);

  @override
  _OtherScheduleState createState() => _OtherScheduleState();
}

class _OtherScheduleState extends State<OtherSchedule> {
  String get desc => widget.object.description;
  String get name => widget.object.name;
  String get id => widget.object.id;
  bool isScheduleLoaded = false;

  DataSource events;
  @override
  void initState() {
    super.initState();
    _uploadSchedule();
  }

  void _uploadSchedule() {
    DateFormat formatter = DateFormat('yyyy.MM.dd');
    DateTime now = DateTime.now();
    getSchedule(
      type: widget.type,
      ruzId: id,
      startDate: formatter.format(now.subtract(Duration(days: 2))),
      endDate: formatter.format(now.add(Duration(days: 21))),
    ).then((scheduleJson) {
      print('Got $name schedule');
      getAppointments(scheduleJson: scheduleJson).then((value) => setState(() {
            events = DataSource(value);
            isScheduleLoaded = true;
          }));
    });
  }

  void openAppointment(CalendarTapDetails details) {
    List<dynamic> res = details.appointments;
    if (res != null) {
      String notesEncoded = res[0].notes;
      var notesDecoded = json.decode(notesEncoded);
      Navigator.of(context).push(_openSubjectRoute(notesDecoded));
    }
  }

  Route _openSubjectRoute(notesDecoded) {
    return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SubjectPage(notes: notesDecoded),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var tween = Tween(begin: const Offset(1, 1), end: Offset.zero)
              .chain(CurveTween(curve: Curves.ease));

          return SlideTransition(
              position: animation.drive(tween), child: child);
        });
  }

  Widget getMainWidget() {
    return MyCalendar(
      events: events,
      openSubjectInfo: (details) => openAppointment(details),
      viewType: CalendarView.schedule,
      onLongPressFunc: (details) => () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        goBackHome(context);
        return;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
              title: ListTile(
                contentPadding: EdgeInsets.all(0),
                title: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle:
                    Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              backgroundColor: Colors.white,
              elevation: 5,
              leading: IconButton(
                  icon:
                      Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
                  onPressed: () => goBackHome(context))),
          body: getMainWidget(),
        ),
      ),
    );
  }
}
