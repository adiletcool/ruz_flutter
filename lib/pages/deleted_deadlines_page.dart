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

class DeletedDeadlinesPage extends StatefulWidget {
  @override
  _DeletedDeadlinesPageState createState() => _DeletedDeadlinesPageState();
}

class _DeletedDeadlinesPageState extends State<DeletedDeadlinesPage> {
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
          isDeleted Text,
          isDone Text)
      ''');
      },
    );
  }

  Future<void> _getDeletedDeadlines() async {
    List<Map> jsons = await _db
        .rawQuery('SELECT * FROM $kDbTableName  WHERE isDeleted = "true"');
    print('${jsons.length} rows retrieved from db!');

    _deadlines = jsons.map((json) => Deadline.fromJsonMap(json)).toList();
    events = DataSource(await getDDAppointments(deadlines: _deadlines));
    setState(() {});
  }

  Future<bool> _asyncInit() async {
    await _memoizer.runOnce(() async {
      await _initDb();
      await _getDeletedDeadlines();
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
                Text('Удаленные', style: dlinesDDTextStyle),
                SizedBox(width: 20),
                IconButton(
                  icon: Icon(MdiIcons.deleteAlertOutline, size: 28),
                  onPressed: () {
                    // TODO: alert dialog: удалить все (for Deadline deletedDD in _deadlines) ...
                    Fluttertoast.showToast(
                      msg: 'Удалить все',
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
