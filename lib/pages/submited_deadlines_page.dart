import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path/path.dart';
import 'package:ruz/pages/deadline_page.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../constants.dart';
import 'deadlines_page.dart' show Deadline, DeadlinesPage;
import 'package:ruz/main.dart' show DataSource, MyCalendar, openRoute;

class SubmitedDeadlinesPage extends StatefulWidget {
  @override
  _SubmitedDeadlinesPageState createState() => _SubmitedDeadlinesPageState();
}

class _SubmitedDeadlinesPageState extends State<SubmitedDeadlinesPage> {
  Database _db;
  DataSource events = DataSource([]);
  List<Deadline> _deadlines = [];
  final AsyncMemoizer _memoizer = AsyncMemoizer();

  Future<void> _initDb() async {
    final dbFolder = await getDatabasesPath();

    if (!await Directory(dbFolder).exists()) {
      await Directory(dbFolder).create(recursive: true);
    }
    final dbPath = join(dbFolder, kDbFileName);

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
        CREATE TABLE $kDbTableName(
          id INTEGER PRIMARY KEY, 
          list TEXT,
          title TEXT,
          description TEXT,
          dateEnd TEXT,
          timeEnd TEXT,
          isDone Text)
      ''');
      },
    );
  }

  Future<void> _getSubmitedDeadlines() async {
    List<Map> jsons = await _db.rawQuery('SELECT * FROM $kDbTableName  WHERE isDone = "true"');
    print('${jsons.length} rows retrieved from db!');

    _deadlines = jsons.map((json) => Deadline.fromJsonMap(json)).toList();
    events = DataSource(await getDDAppointments(deadlines: _deadlines));
    setState(() {});
  }

  Future<bool> _asyncInit() async {
    await _memoizer.runOnce(() async {
      await _initDb();
      await _getSubmitedDeadlines();
    });
    return true;
  }

  Widget getMainBody(BuildContext context) {
    return MyCalendar(
        viewType: CalendarView.schedule,
        events: events,
        openSubjectInfo: (CalendarTapDetails details) {
          List<dynamic> res = details.appointments;
          if (res != null) {
            var appNotes = json.decode(details.appointments[0].notes);
            openRoute(context,
                page: DeadlinePage(
                  currentList: appNotes['list'],
                  existingNotes: appNotes,
                ));
          }
        },
        onLongPressFunc: (CalendarLongPressDetails details) {});
  }

  Future<void> _deleteForeverDeadline(deadlineId) async {
    await this._db.rawDelete('''
        DELETE FROM $kDbTableName
        WHERE id = "$deadlineId"
      ''');
    print('Deleted deadline with id=$deadlineId');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: FutureBuilder<bool>(
      future: _asyncInit(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == false)
          return Center(
            child: CircularProgressIndicator(),
          );
        List<Widget> mainBodyStackChildren = [
          getMainBody(context),
          Positioned(
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () => openRoute(context, page: DeadlinesPage()),
                ),
                Text('Выполненные', style: dlinesDDTextStyle),
                SizedBox(width: 20),
                if (_deadlines.isNotEmpty)
                  IconButton(
                    icon: Icon(MdiIcons.deleteAlertOutline, size: 28),
                    onPressed: () {
                      List<String> submitedIds = List.generate(_deadlines.length, (index) => _deadlines[index].id.toString());
                      for (String ddId in submitedIds) {
                        _deleteForeverDeadline(ddId);
                      }
                      setState(() => _getSubmitedDeadlines());
                      Fluttertoast.showToast(
                        msg: 'Все завершенные дедлайны удалены',
                        textColor: Colors.white,
                        backgroundColor: Colors.black,
                      );
                    },
                  ),
              ],
            ),
          ),
        ];
        if (_deadlines.length == 0) {
          mainBodyStackChildren.add(Positioned(
            child: Center(
              child: Text('У вас еще нет удаленных дедлайнов'),
            ),
          ));
        }
        return Scaffold(body: Stack(children: mainBodyStackChildren));
      },
    ));
  }
}
