import 'dart:convert';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:ruz/constants.dart';
import 'package:ruz/main.dart' show MyCalendar, DataSource, openRoute;
import 'package:ruz/pages/deadline_page.dart';
import 'package:ruz/pages/deleted_deadlines_page.dart';
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

  void _changeCurrentListUpdate(context, listName) {
    currentList = listName;
    _saveSettings();
    openRoute(context, page: DeadlinesPage());
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
          dateEnd TEXT,
          isDeleted Text,
          isDone Text)
      ''');
      },
    );
  }

  Future<void> _getDeadlines(currentList) async {
    List<Map> jsons = await _db.rawQuery(
        'SELECT * FROM $kDbTableName  WHERE (list = "$currentList" AND isDeleted = "false" AND isDone = "false")');
    print('${jsons.length} rows retrieved from db!');

    _deadlines = jsons.map((json) => Deadline.fromJsonMap(json)).toList();
    events = DataSource(await getDDAppointments(deadlines: _deadlines));
    setState(() {});
  }

  Future<void> _deleteDeadline(deadlineId) async {
    _db.transaction((Transaction txn) async {
      int id = await txn.rawUpdate('''
        UPDATE $kDbTableName
        SET isDeleted = "true"
        WHERE id == $deadlineId
        ''');
      print('Deleted deadline with id=$id');
    });
    Fluttertoast.showToast(
      msg: 'Удалено',
      textColor: Colors.white,
      backgroundColor: Colors.black,
    );
    await _getDeadlines(currentList);
  }

  void _deleteCurrentList(BuildContext ctx) {
    if (currentList == 'Мой список') {
      Fluttertoast.showToast(
        msg: 'Нельзя удалить стандартный список',
        textColor: Colors.white,
        backgroundColor: Colors.black,
      );
      Navigator.pop(ctx);
    } else {
      for (Deadline deadline in _deadlines) _deleteDeadline(deadline.id);
      availableLists.remove(currentList);
      Fluttertoast.showToast(
        msg: 'Список $currentList удален',
        textColor: Colors.white,
        backgroundColor: Colors.black,
      );
      _changeCurrentListUpdate(ctx, 'Мой список');
    }
  }

  Future<bool> _asyncInit() async {
    await _memoizer.runOnce(() async {
      await _getCurrentList();
      await _initDb();
      await _getDeadlines(currentList);
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
          Map<String, dynamic> appNotes =
              json.decode(details.appointments[0].notes);

          openRoute(context,
              page: DeadlinePage(
                currentList: currentList,
                existingNotes: appNotes,
              ),
              beginOffset: Offset(0, 1));
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
      onPressed: () {
        openRoute(context,
            page: DeadlinePage(currentList: currentList),
            beginOffset: Offset(0, 1));
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
                              if (currentList != value)
                                _changeCurrentListUpdate(context, value);
                              else
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
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: ListTile(
                        leading:
                            Icon(Icons.delete_outline, color: Colors.black),
                        title: Text('Удаленные', style: dlinesDDTextStyle),
                        onTap: () =>
                            openRoute(context, page: DeletedDeadlinesPage()),
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
                      onTap: () => _deleteCurrentList(context),
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
                      _changeCurrentListUpdate(context, _titleController.text);
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
  final String isDeleted;
  final String isDone;

  const Deadline({
    this.id,
    this.list,
    this.title,
    this.description,
    this.dateEnd,
    this.isDeleted,
    this.isDone,
  });

  Deadline.fromJsonMap(Map<String, dynamic> map)
      : id = map['id'],
        list = map['list'],
        title = map['title'],
        description = map['description'],
        dateEnd = map['dateEnd'],
        isDeleted = map['isDeleted'],
        isDone = map['isDone'];

  Map<String, dynamic> toJsonMap() => {
        'list': list,
        'title': title,
        'description': description,
        'dateEnd': dateEnd,
        'isDeleted': isDeleted,
        'isDone': isDone,
      };

  @override
  String toString() {
    return 'Deadline(title: $title, description: $description, date: $dateEnd\n)';
  }
}
