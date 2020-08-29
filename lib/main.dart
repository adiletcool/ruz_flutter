import 'dart:convert';
import 'package:intl/intl.dart';
import 'constants.dart';
import 'ruz.dart';
import 'pages/settings.dart';
import 'pages/search_group.dart';
import 'pages/search_student.dart';
import 'pages/subject_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ruz/pages/settings.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  SyncfusionLicense.registerLicense(licenseKey);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      theme: ThemeData(fontFamily: 'PTRootUI'),
      routes: {
        'HomePage': (context) => HomePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  _DataSource events;
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();
  bool isTable = false;
  Icon viewIcon = Icon(MdiIcons.viewWeekOutline);
  CalendarView viewType = CalendarView.schedule;

  String scheduleType;
  String groupId;
  String groupName = '';
  String studentName = '';
  String studentId;
  bool isSettingsLoaded = false;

  @override
  void initState() {
    super.initState();
    getSettings().then((res) {
      setState(() {
        scheduleType = res['selectedType'];
        groupId = res['selectedGroupId'];
        groupName = res['selectedGroupName'] ??= '';
        studentName = res['selectedStudentName'] ??= '';
        studentId = res['selectedStudentId'];
        isSettingsLoaded = true;
      });

      var ruzId = scheduleType == 'group' ? groupId : studentId;

      if (ruzId != null) {
        DateFormat formatter = DateFormat('yyyy.MM.dd');
        DateTime now = DateTime.now();
        getAppointmentsByGroup(
          type: scheduleType == 'group' ? scheduleType : 'student',
          ruzId: ruzId, // read from file
          startDate: formatter.format(now.subtract(Duration(days: 2))),
          endDate: formatter.format(now.add(Duration(days: 21))),
        ).then((value) => setState(() => events = _DataSource(value)));
      } else
        setState(() => events = _DataSource([]));
    });
  }

  void switchView() {
    setState(() {
      isTable = !isTable;
      viewType = isTable ? CalendarView.week : CalendarView.schedule;
      viewIcon = isTable
          ? Icon(MdiIcons.viewDayOutline)
          : Icon(MdiIcons.viewWeekOutline);
    });
  }

  void openSubjectInfo(CalendarTapDetails details) {
    List<dynamic> res = details.appointments;
    if (res != null) {
      String notesEncoded = res[0].notes;
      var notesDecoded = json.decode(notesEncoded);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SubjectPage(notes: notesDecoded)));
    }
  }

  String getStudentName() {
    if (studentName == 'Find your name')
      return 'Set name';
    else if (studentName != '')
      return studentName.split(' ')[1];
    else
      return studentName; // ''
  }

  @override
  Widget build(BuildContext context) {
    Widget mainBody = Stack(
      alignment: AlignmentDirectional.topStart,
      children: <Widget>[
        MyCalendar(
            viewType: viewType,
            events: events,
            openSubjectInfo: (details) => openSubjectInfo(details)),
        IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => _drawerKey.currentState.openDrawer()),
        Positioned(
            left: 60,
            child: IconButton(icon: viewIcon, onPressed: () => switchView())),
        Positioned(
            // top: 12,
            left: 120,
            child: FlatButton(
              child: Text(
                scheduleType == 'group' ? groupName : getStudentName(),
                style: searchTextStyle.copyWith(fontWeight: FontWeight.w600),
              ),
              onPressed: () => openSettingsPage(context),
            ))
      ],
    );

    Widget firstLaunchBody = Center(
      child: OutlineButton(
        child: Text('Set schedule settings', style: dateStyle),
        onPressed: () => openSettingsPage(context),
      ),
    );

    Widget getMainBody() {
      if (scheduleType != null)
        return mainBody;
      else if (isSettingsLoaded)
        return firstLaunchBody;
      else
        return Center(child: CircularProgressIndicator());
    }

    return WillPopScope(
      onWillPop: () async {
        if (_drawerKey.currentState.isDrawerOpen)
          Navigator.pop(context);
        else
          SystemNavigator.pop();
        return;
      },
      child: SafeArea(
        child: Scaffold(
          key: _drawerKey,
          drawer: HomeDrawer(),
          body: getMainBody(),
        ),
      ),
    );
  }
}

class MyCalendar extends StatelessWidget {
  const MyCalendar({
    Key key,
    @required this.viewType,
    @required this.events,
    @required this.openSubjectInfo,
  }) : super(key: key);

  final CalendarView viewType;
  final _DataSource events;
  final Function openSubjectInfo;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return SfCalendar(
      view: viewType,
      dataSource: events,
      onTap: (CalendarTapDetails details) => openSubjectInfo(details),
      firstDayOfWeek: 1,
      appointmentTimeTextFormat: 'HH:mm',
      timeSlotViewSettings: TimeSlotViewSettings(
        timeFormat: 'HH:mm',
        startHour: 8,
        endHour: 23,
        timeInterval: Duration(minutes: 30),
        timeTextStyle: timeTextStyle,
      ),
      viewHeaderStyle: ViewHeaderStyle(
        dateTextStyle: dateTextStyle,
        dayTextStyle: dateTextStyle,
      ),
      initialDisplayDate: DateTime(now.year, now.month, now.day, 8, 0),
      todayHighlightColor: HexColor.fromHex('#1b5c94'),
      scheduleViewSettings: ScheduleViewSettings(
        appointmentTextStyle: mainStyle.copyWith(),
        dayHeaderSettings: DayHeaderSettings(dateTextStyle: dateStyle),
        hideEmptyScheduleWeek: true,
        monthHeaderSettings: MonthHeaderSettings(
          backgroundColor: HexColor.fromHex('#27363b'),
          height: 60,
          monthTextStyle: monthStyle.copyWith(height: 0.7),
        ),
        weekHeaderSettings: WeekHeaderSettings(
          weekTextStyle: mainStyle.copyWith(color: Colors.blueGrey),
        ),
      ),
      headerStyle: CalendarHeaderStyle(
        textStyle: headerStyle,
        textAlign: TextAlign.end,
      ),
    );
  }
}

class _DataSource extends CalendarDataSource {
  _DataSource(List<Appointment> source) {
    appointments = source;
  }
}

class HomeDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: HexColor.fromHex('#212529').withOpacity(.92),
      ),
      child: Container(
        width: 220,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.only(left: 20),
                // leading: IconButton(
                //   icon: Icon(Icons.menu, color: Colors.white),
                //   onPressed: () => Navigator.pop(context),
                // ),
                title: Text('Schedule', style: drawerTextStyle),
              ),
              Divider(color: Colors.white, thickness: 1.2),
              ListTile(
                leading: Icon(Icons.schedule, size: 18, color: Colors.white),
                title: Text('Deadlines',
                    style: drawerTextStyle.copyWith(fontSize: 19, height: .7)),
                onTap: () {},
              ),
              Divider(color: Colors.white),
              ListTile(
                  leading: Icon(Icons.settings, size: 18, color: Colors.white),
                  title: Text('Settings',
                      style:
                          drawerTextStyle.copyWith(fontSize: 19, height: .7)),
                  onTap: () => openSettingsPage(context)),
              ListTile(
                leading:
                    Icon(Icons.info_outline, size: 18, color: Colors.white),
                title: Text('Info',
                    style: drawerTextStyle.copyWith(fontSize: 19, height: .7)),
                onTap: () => showInfoDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showInfoDialog(BuildContext context) {
  Navigator.pop(context);
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(0),
          content: InkWell(
            child: Container(
              padding: EdgeInsets.all(8),
              child: ListTile(
                leading: SvgPicture.asset(
                  'assets/icons/logo_vk_outline.svg',
                  width: 30,
                ),
                title: Text('Abiraev Adilet',
                    style: settingsMidRowStyle.copyWith(
                      fontSize: 22,
                      color: Colors.blueAccent,
                    )),
              ),
            ),
            onTap: () async => launch('https://vk.com/adilet_abiraev'),
          ),
        );
      });
}

void openSettingsPage(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => GroupBloc()),
          BlocProvider(create: (_) => StudentBloc()),
        ],
        child: SettingsPage(),
      );
    }),
  );
}
