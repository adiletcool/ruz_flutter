import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ruz/pages/search.dart';
import 'constants.dart';
import 'pages/other_schedule.dart';
import 'ruz.dart';
import 'pages/settings.dart';
import 'pages/subject_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return BlocProvider(
        create: (_) => ObjBloc(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(),
          theme: ThemeData(fontFamily: 'PTRootUI'),
          routes: {
            'HomePage': (context) => HomePage(),
          },
        ));
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DataSource events;
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();
  bool isTable = false;
  Icon viewIcon = Icon(MdiIcons.viewWeekOutline);
  CalendarView viewType = CalendarView.schedule;

  String scheduleType;
  String groupId;
  String groupName = '';
  String studentName = '';
  String studentId;
  String ruzId;
  bool isScheduleLoaded = false;
  bool isInternetConnError = false;

  void _uploadSchedule() {
    if (ruzId != null) {
      DateFormat formatter = DateFormat('yyyy.MM.dd');
      DateTime now = DateTime.now();
      getSchedule(
        type: scheduleType,
        ruzId: ruzId,
        startDate: formatter.format(now.subtract(Duration(days: 2))),
        endDate: formatter.format(now.add(Duration(days: 21))),
      ).then((scheduleJson) {
        if (scheduleJson.length > 0) {
          if (scheduleJson[0].runtimeType == SocketException) {
            print('Internet Error');
            setState(() {
              isInternetConnError = true;
              events = DataSource([]);
            });
            return;
          }
        }
        print('Got Appointments');
        getAppointments(scheduleJson: scheduleJson)
            .then((value) => setState(() {
                  events = DataSource(value);
                  isScheduleLoaded = true;
                  isInternetConnError = false;
                }));
      });
    } else
      setState(() {
        events = DataSource([]);
        isScheduleLoaded = true;
        isInternetConnError = false;
      });
  }

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
        ruzId = scheduleType == 'group' ? groupId : studentId;
      });
      _uploadSchedule();
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

  String getStudentName() {
    if (studentName == 'Find your name')
      return 'Set name';
    else if (studentName != '')
      return studentName.split(' ')[1];
    else
      return studentName; // ''
  }

  Widget getMainWidget(BuildContext context) {
    return Stack(
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
              onPressed: () => openRoute(context, page: SettingsPage()),
            ))
      ],
    );
  }

  Widget getFirstLaunchWidget(BuildContext context) {
    return Center(
      child: OutlineButton(
        child: Text('Set schedule settings', style: dateStyle),
        onPressed: () => openRoute(context, page: SettingsPage()),
      ),
    );
  }

  Widget internetConnectionErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Center(child: Text('Internet connection error.', style: dateStyle)),
        SizedBox(height: 15),
        FlatButton(
            color: Colors.blueGrey,
            child: Text('Retry', style: settingsTextStyle),
            onPressed: () {
              _uploadSchedule();
            })
      ],
    );
  }

  Widget getMainBody() {
    if (!isInternetConnError) {
      if (scheduleType != null) {
        return getMainWidget(context);
      } else if (isScheduleLoaded)
        return getFirstLaunchWidget(context);
      else
        return Center(child: CircularProgressIndicator());
    } else {
      return internetConnectionErrorWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
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
  final DataSource events;
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

class DataSource extends CalendarDataSource {
  DataSource(List<Appointment> source) {
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
                title: Text('Schedule', style: drawerTextStyle),
              ),
              Divider(color: Colors.white, thickness: 1.2),
              ListTile(
                  leading: HomeDrawerIcon.icon(Icons.room),
                  title: Text('Classrooms', style: homeDrawerTextStyle),
                  onTap: () async {
                    String type = 'auditorium';
                    Obj selectedValue = await showSearch(
                        context: context,
                        delegate:
                            ObjSearch(BlocProvider.of<ObjBloc>(context), type));
                    openRoute(context,
                        page: OtherSchedule(selectedValue, type));
                  }),
              ListTile(
                leading: HomeDrawerIcon.icon(MdiIcons.teach),
                title: Text('Teachers', style: homeDrawerTextStyle),
                onTap: () async {
                  String type = 'lecturer';

                  Obj selectedValue = await showSearch(
                      context: context,
                      delegate:
                          ObjSearch(BlocProvider.of<ObjBloc>(context), type));
                  openRoute(context, page: OtherSchedule(selectedValue, type));
                },
              ),
              ListTile(
                leading: HomeDrawerIcon.icon(Icons.schedule),
                title: Text('Deadlines', style: homeDrawerTextStyle),
                onTap: () {},
              ),
              Divider(color: Colors.white),
              ListTile(
                  leading: HomeDrawerIcon.icon(Icons.settings),
                  title: Text('Settings', style: homeDrawerTextStyle),
                  onTap: () => openRoute(context, page: SettingsPage())),
              ListTile(
                leading: HomeDrawerIcon.icon(Icons.info_outline),
                title: Text('Info', style: homeDrawerTextStyle),
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
          content: Container(
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => launch('https://vk.com/adilet_abiraev'),
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
                Divider(color: Colors.black87),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.only(left: 22, bottom: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('App icon: ', style: TextStyle(fontSize: 18)),
                      InkWell(
                        onTap: () => launch('https://icons8.com'),
                        child: Text('icons8',
                            style: settingsMidRowStyle.copyWith(
                              fontSize: 18,
                              color: Colors.blueAccent,
                            )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      });
}

void openRoute(BuildContext context, {@required Widget page}) {
  Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.ease));

        return SlideTransition(position: animation.drive(tween), child: child);
      }));
}
