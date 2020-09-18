import 'dart:convert';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:ruz/constants.dart';
import 'package:ruz/main.dart' show MyCalendar, DataSource;
import 'package:ruz/pages/deadline_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DeadlinesPage extends StatefulWidget {
  const DeadlinesPage({Key key}) : super(key: key);
  @override
  _DeadlinesPageState createState() => _DeadlinesPageState();
}

class _DeadlinesPageState extends State<DeadlinesPage> {
  DataSource events = DataSource([]);

  String currentList;
  List<String> availableLists;
  Database _db;
  List<Deadline> _deadlines = [];
  final AsyncMemoizer _memoizer = AsyncMemoizer();

  Future<void> _getCurrentList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentList = prefs.getString('currentList') ?? 'Мой список';
    availableLists = prefs.getStringList('availableLists') ?? [currentList];
    _saveSettings();
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('currentList', currentList);
    prefs.setStringList('availableLists', availableLists);
  }

  void _changeCurrentListUpdate(listName) {
    currentList = listName;
    _saveSettings();
    _getDeadlines(currentList);
  }

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
          dateEnd TEXT)
      ''');
      },
    );
  }

  Future<void> _getDeadlines(currentList) async {
    List<Map> jsons = await _db
        .rawQuery('SELECT * FROM $kDbTableName  WHERE list = "$currentList"');
    print('${jsons.length} rows retrieved from db!');

    _deadlines = jsons.map((json) => Deadline.fromJsonMap(json)).toList();

    getAppointments().then((value) => events = DataSource(value));
    setState(() {});
  }

  Future<void> _deleteDeadline(deadlineId) async {
    final count = await this._db.rawDelete('''
        DELETE FROM $kDbTableName
        WHERE id = "$deadlineId"
      ''');
    print('Updated $count records in db.');
    _getDeadlines(currentList);
  }

  Future<void> _deleteCurrentList() async {
    if (currentList == 'Мой список') {
      Fluttertoast.showToast(
        msg: 'Нельзя удалить стандартный список',
        textColor: Colors.white,
        backgroundColor: Colors.black,
      );
    } else {
      for (Deadline deadline in _deadlines) _deleteDeadline(deadline.id);
      availableLists.remove(currentList);
      _changeCurrentListUpdate('Мой список');
    }
    setState(() {});
  }

  Future<bool> _asyncInit() async {
    await _memoizer.runOnce(() async {
      await _getCurrentList();
      await _initDb();
      await _getDeadlines(currentList);
    });
    return true;
  }

  Future<List<Appointment>> getAppointments() async {
    return List.generate(_deadlines.length, (i) {
      int id = _deadlines[i].id;
      String list = _deadlines[i].list;
      String title = _deadlines[i].title;
      String description = _deadlines[i].description;
      String dateEnd = _deadlines[i].dateEnd;
      DateTime dateEndDF = DateFormat("dd.MM.yyyy").parse(dateEnd);
      String notesEnc = json.encode({
        'id': id,
        'list': list,
        'title': title,
        'description': description,
        'dateEnd': dateEnd,
      });

      return Appointment(
        subject: title,
        startTime: dateEndDF,
        endTime: dateEndDF,
        isAllDay: true,
        notes: notesEnc,
        color: HexColor.fromHex('#333644'),
      );
    });
  }

  Widget getMainBody(BuildContext context) {
    return MyCalendar(
      viewType: CalendarView.schedule,
      events: events,
      openSubjectInfo: (CalendarTapDetails details) {
        List<dynamic> res = details.appointments;
        if (res != null) {
          Map<String, dynamic> appNotes =
              json.decode(details.appointments[0].notes);

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DeadlinePage(
                        currentList: currentList,
                        existingNotes: appNotes,
                      )));
          print(details.appointments[0].notes);
        }
      },
      onLongPressFunc: (CalendarLongPressDetails details) =>
          onAppointmentLongPress(context, details),
    );
  }

  void onAppointmentLongPress(
      BuildContext context, CalendarLongPressDetails details) {
    Map<String, dynamic> appNotes = json.decode(details.appointments[0].notes);
    showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.done, color: Colors.black),
                  title: Text('Done'),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.black),
                  title: Text('Delete'),
                  onTap: () {
                    _deleteDeadline(appNotes['id']);
                    Navigator.pop(context);
                  },
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          goBackHome(context);
          return;
        },
        child: SafeArea(
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
                          onPressed: () => goBackHome(context),
                        ),
                        Text(currentList, style: dlinesDDTextStyle),
                      ],
                    ),
                  ),
                ];
                if (_deadlines.length == 0) {
                  mainBodyStackChildren.add(Positioned(
                    child: Center(
                      child: Text('Здесь пока пусто, добавьте первый дедлайн'),
                    ),
                  ));
                }
                return Scaffold(
                  body: Stack(
                    children: mainBodyStackChildren,
                  ),
                  floatingActionButtonLocation:
                      FloatingActionButtonLocation.centerDocked,
                  floatingActionButton: _buildfloatingActionButton(context),
                  bottomNavigationBar: this._buildBottomAppBar(context),
                );
              }),
        ));
  }

  FloatingActionButton _buildfloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      elevation: 15,
      child: Icon(Icons.add, size: 40, color: HexColor.fromHex('#34222e')),
      backgroundColor: HexColor.fromHex('#c65f63'),
      onPressed: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeadlinePage(currentList: currentList),
          ),
        );
      },
    );
  }

  BottomAppBar _buildBottomAppBar(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      color: HexColor.fromHex('#FFFFFF'),
      elevation: 15,
      notchMargin: 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: Icon(MdiIcons.menu),
            color: Colors.black,
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                      padding:
                          const EdgeInsets.only(right: 35, left: 30, top: 10),
                      child: Row(
                        children: [
                          Icon(MdiIcons.formSelect, color: Colors.black),
                          SizedBox(width: 30),
                          DropdownButton(
                            underline: Container(),
                            value: currentList,
                            onChanged: (value) {
                              _changeCurrentListUpdate(value);
                              Navigator.pop(context);
                            },
                            items: availableLists
                                .map((String listName) =>
                                    DropdownMenuItem<String>(
                                      value: listName,
                                      child: Text(listName,
                                          style: dlinesDDTextStyle),
                                    ))
                                .toList(),
                          ),
                        ],
                      )),
                  Divider(color: Colors.black45),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: ListTile(
                        leading: Icon(Icons.add, color: Colors.black),
                        title: Text('Создать список', style: dlinesDDTextStyle),
                        onTap: () => createListBottomSheet(context),
                      )),
                  Divider(color: Colors.black45),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: ListTile(
                        leading: Icon(Icons.done, color: Colors.black),
                        title: Text('Выполненные', style: dlinesDDTextStyle),
                        onTap: () {},
                      )),
                  Divider(color: Colors.black45),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(MdiIcons.dotsVertical),
            color: Colors.black,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.delete_sweep, color: Colors.black),
                      title: Text('Удалить список', style: dlinesDDTextStyle),
                      onTap: () {
                        _deleteCurrentList();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void createListBottomSheet(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    String _titleValidator(String title) {
      if (title.isEmpty) return 'Поле не может быть пустым';
      if (availableLists.contains(title))
        return 'Список с таким именем уже существует';
      return null;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.symmetric(horizontal: 0),
        insetPadding: EdgeInsets.symmetric(horizontal: 5),
        scrollable: false,
        content: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.all(0),
                leading: IconButton(
                    icon: Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context)),
                title: Text('Новый список',
                    style: dlinesDDTextStyle.copyWith(
                        fontWeight: FontWeight.w600)),
                trailing: FlatButton(
                  child: Text('Готово',
                      style: TextStyle(color: Colors.blue, fontSize: 17)),
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      availableLists.add(_titleController.text);
                      _changeCurrentListUpdate(_titleController.text);
                      _saveSettings();
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              Divider(color: Colors.black, height: 0),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    autofocus: true,
                    maxLength: 40,
                    validator: _titleValidator,
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Название списка',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Deadline {
  final int id;
  final String list;
  final String title;
  final String description;
  final String dateEnd; //dd.MM.yyyy

  const Deadline(
      {this.id, this.list, this.title, this.description, this.dateEnd});

  Deadline.fromJsonMap(Map<String, dynamic> map)
      : id = map['id'],
        list = map['list'],
        title = map['title'],
        description = map['description'],
        dateEnd = map['dateEnd'];

  Map<String, dynamic> toJsonMap() => {
        'title': title,
        'description': description,
        'dateEnd': dateEnd,
      };

  @override
  String toString() {
    return 'Deadline(title: $title, description: $description, date: $dateEnd\n)';
  }
}
