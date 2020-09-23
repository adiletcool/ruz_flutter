import 'dart:io';
import 'package:ruz/main.dart';
import 'package:ruz/pages/submited_deadlines_page.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'deadlines_page.dart' show Deadline, DeadlinesPage;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path/path.dart';
import 'package:ruz/constants.dart';
import 'package:sqflite/sqflite.dart';

class DeadlinePage extends StatefulWidget {
  final Map<String, dynamic> existingNotes;
  final String currentList;

  const DeadlinePage({this.existingNotes, this.currentList});
  @override
  _DeadlinePageState createState() => _DeadlinePageState(existingNotes);
}

class _DeadlinePageState extends State<DeadlinePage> {
  final existingNotes;

  final _formKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();
  TextEditingController descController = TextEditingController();
  String dateSet = DateFormat("dd.MM.yyyy").format(DateTime.now());
  String timeSet = DateFormat("HH:mm").format(DateTime.now());
  Database _db;
  Color dateIconColor = HexColor.fromHex('#33658a');

  _DeadlinePageState(this.existingNotes);

  String _titleValidator(String title) {
    if (title.isEmpty) return 'Title is required';
    return null;
  }

  Future<void> _initDb() async {
    final dbFolder = await getDatabasesPath();
    if (!await Directory(dbFolder).exists()) {
      await Directory(dbFolder).create(recursive: true);
    }
    final dbPath = join(dbFolder, kDbFileName);
    _db = await openDatabase(dbPath, version: 1);
  }

  Future<void> _addDeadline(Deadline deadline) async {
    _db.transaction((Transaction txn) async {
      int id = await txn.rawInsert('''
        INSERT INTO $kDbTableName (list, title, description, dateEnd, timeEnd, isDone)
        VALUES ("${deadline.list}", "${deadline.title}", "${deadline.description}",
         "${deadline.dateEnd}", "${deadline.timeEnd}", "${deadline.isDone}")
      ''');
      print('Inserted deadline with id=$id.');
    });
  }

  Future<void> _changeDeadline(int ddId, String newTitle, String newDescription, String newDate, String newTime) async {
    _db.transaction((Transaction txn) async {
      int id = await txn.rawUpdate('''
        UPDATE $kDbTableName
        SET title = "$newTitle", description = "$newDescription", dateEnd =  "$newDate", timeEnd = "$newTime"
        WHERE id = $ddId
        ''');
      print('Changed deadline with id=$id');
    });
    if (widget.existingNotes['title'] != newTitle ||
        widget.existingNotes['description'] != newDescription ||
        widget.existingNotes['dateEnd'] != newDate ||
        widget.existingNotes['timeEnd'] != newTime) {
      Fluttertoast.showToast(
        msg: 'Изменения сохранены',
        textColor: Colors.white,
        backgroundColor: Colors.black,
      );
    }
  }

  Future<void> _submitDeadline(deadlineId) async {
    _db.transaction((Transaction txn) async {
      int id = await txn.rawUpdate('''
        UPDATE $kDbTableName
        SET isDone = "true"
        WHERE id = $deadlineId
        ''');
      print('Submited deadline with id=$id');
    });
  }

  Future<void> _unSubmitDeadline(deadlineId) async {
    _db.transaction((Transaction txn) async {
      int id = await txn.rawUpdate('''
        UPDATE $kDbTableName
        SET isDone = "false"
        WHERE id = $deadlineId
        ''');
      print('Restored deadline with id=$id');
    });
  }

  Future<void> _deleteForeverDeadline(deadlineId) async {
    await this._db.rawDelete('''
        DELETE FROM $kDbTableName
        WHERE id = "$deadlineId"
      ''');
    print('Deleted deadline with id=$deadlineId');
  }

  @override
  void initState() {
    super.initState();
    _initDb();

    if (existingNotes != null) {
      titleController = TextEditingController(text: existingNotes['title']);
      descController = TextEditingController(text: existingNotes['description']);
      dateSet = existingNotes['dateEnd'];
      timeSet = existingNotes['timeEnd'];
    }
  }

  bool isTextFieldAvailable() {
    if (widget.existingNotes != null && widget.existingNotes['isDone'] == 'true')
      return false;
    else
      return true;
  }

  Widget getMainBody(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(widget.currentList, style: timeTextStyle),
                  // Title
                  TextFormField(
                    enabled: isTextFieldAvailable(),
                    controller: titleController,
                    autofocus: (widget.existingNotes == null),
                    validator: _titleValidator,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Новый дедлайн*',
                    ),
                    style: TextStyle(fontSize: 22),
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  Divider(color: Colors.black),
                  SizedBox(height: 10),
                  // Description
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        flex: 1,
                        child: Icon(MdiIcons.textSubject, size: 28, color: HexColor.fromHex('#33658a')),
                      ),
                      Flexible(
                        flex: 9,
                        child: TextFormField(
                          enabled: isTextFieldAvailable(),
                          controller: descController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Добавьте описание',
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 15,
                          style: TextStyle(fontSize: 17),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: <Widget>[
                      Flexible(
                        flex: 1,
                        child: Icon(Icons.calendar_today, color: dateIconColor),
                      ),
                      SizedBox(width: 10),
                      Theme(
                        data: ThemeData(
                          colorScheme: ColorScheme.light(
                            primary: HexColor.fromHex('#33658a'),
                          ),
                        ),
                        child: Builder(
                          builder: (context) => Row(
                            children: <Widget>[
                              // DatePicker
                              FlatButton(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: HexColor.fromHex('#33658a')),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  dateSet,
                                  style: TextStyle(fontSize: 17, color: HexColor.fromHex('#33658a')),
                                ),
                                onPressed: () {
                                  if (isTextFieldAvailable()) {
                                    DatePicker.showDatePicker(
                                      context,
                                      showTitleActions: true,
                                      minTime: DateTime.now(),
                                      maxTime: DateTime.now().add(Duration(days: 365 * 5)),
                                      locale: LocaleType.ru,
                                      currentTime: DateFormat("dd.MM.yyyy").parse(dateSet),
                                      onConfirm: (DateTime value) {
                                        if (value != null) setState(() => dateSet = DateFormat("dd.MM.yyyy").format(value));
                                      },
                                    );
                                  }
                                },
                              ),
                              SizedBox(width: 20),
                              // TimePicker
                              FlatButton(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: HexColor.fromHex('#33658a')),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  timeSet,
                                  style: TextStyle(fontSize: 17, color: HexColor.fromHex('#33658a')),
                                ),
                                onPressed: () {
                                  if (isTextFieldAvailable()) {
                                    FocusScope.of(context).unfocus(); // hide keyboard
                                    DatePicker.showTimePicker(
                                      context,
                                      currentTime: DateFormat("HH:mm").parse(timeSet),
                                      showSecondsColumn: false,
                                      locale: LocaleType.ru,
                                      onConfirm: (DateTime value) {
                                        if (value != null) setState(() => timeSet = DateFormat("HH:mm").format(value));
                                      },
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> appBarActions = (widget.existingNotes != null)
        ? widget.existingNotes['isDone'] == 'false'
            ? <Widget>[
                IconButton(
                  tooltip: 'Удалить',
                  icon: Icon(Icons.delete_outline, color: Colors.black, size: 28),
                  onPressed: () {
                    int ddId = widget.existingNotes['id'];
                    _deleteForeverDeadline(ddId);
                    Navigator.pushNamed(context, 'DeadlinesPage');
                    Fluttertoast.showToast(
                      msg: 'Удалено',
                      textColor: Colors.white,
                      backgroundColor: Colors.black,
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Выполнено',
                  icon: Icon(MdiIcons.calendarCheckOutline, color: Colors.black, size: 28),
                  onPressed: () {
                    int ddId = widget.existingNotes['id'];
                    _submitDeadline(ddId);
                    Navigator.pushNamed(context, 'DeadlinesPage');
                    Fluttertoast.showToast(
                      msg: 'Выполнено',
                      textColor: Colors.white,
                      backgroundColor: Colors.black,
                    );
                  },
                ),
              ]
            : <Widget>[
                IconButton(
                    tooltip: 'Удалить навсегда',
                    icon: Icon(Icons.delete_forever, color: Colors.black, size: 28),
                    onPressed: () {
                      int ddId = widget.existingNotes['id'];
                      _deleteForeverDeadline(ddId);
                      openRoute(context, page: SubmitedDeadlinesPage());
                      Fluttertoast.showToast(
                        msg: 'Удалено',
                        textColor: Colors.white,
                        backgroundColor: Colors.black,
                      );
                    }),
                IconButton(
                    tooltip: 'Восстановить',
                    icon: Icon(Icons.restore, color: Colors.black, size: 28),
                    onPressed: () {
                      int ddId = widget.existingNotes['id'];
                      _unSubmitDeadline(ddId);
                      openRoute(context, page: DeadlinesPage());
                      Fluttertoast.showToast(
                        msg: 'Восстановлено',
                        textColor: Colors.white,
                        backgroundColor: Colors.black,
                      );
                    }),
              ]
        : [
            FlatButton(
              child: Text('Сохранить', style: TextStyle(color: HexColor.fromHex('#33658a'), fontSize: 17)),
              onPressed: () async {
                if (_formKey.currentState.validate()) {
                  FocusScope.of(context).unfocus(); // hide keyboard
                  await _addDeadline(Deadline(
                    list: widget.currentList,
                    title: titleController.text,
                    description: descController.text,
                    dateEnd: dateSet,
                    timeEnd: timeSet,
                    isDone: 'false',
                  ));
                  Navigator.pushNamed(context, 'DeadlinesPage');
                }
              },
            )
          ];

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamed(context, 'DeadlinesPage');
        return;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: appBarActions,
            leading: IconButton(
              tooltip: (widget.existingNotes != null) ? 'Сохранить и выйти' : 'Отмена',
              icon: (widget.existingNotes != null && widget.existingNotes['isDone'] == 'false')
                  ? Text('Ок',
                      style: headerStyle.copyWith(
                        color: HexColor.fromHex('#33658a'),
                      ))
                  : Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () {
                if (widget.existingNotes != null) {
                  int ddId = existingNotes['id'];
                  _changeDeadline(
                    ddId,
                    titleController.text,
                    descController.text,
                    dateSet,
                    timeSet,
                  );
                }
                if (widget.existingNotes != null && widget.existingNotes['isDone'] == 'true')
                  openRoute(context, page: SubmitedDeadlinesPage());
                else
                  Navigator.pushNamed(context, 'DeadlinesPage');
              },
            ),
          ),
          body: getMainBody(context),
        ),
      ),
    );
  }
}
