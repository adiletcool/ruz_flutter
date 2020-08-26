import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ruz/HexColor.dart';
import 'package:ruz/pages/settings.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'HexColor.dart';
import 'constants.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'ruz.dart';
import 'pages/search_group.dart';
import 'pages/settings.dart';

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

  @override
  void initState() {
    super.initState();
    getAppointments(
      groupId: '12435', // read from file
      startDate: '2020.08.31', //DateTime.now().subtract(Duration(days: 2))
      endDate: '2020.09.23', //DateTime.now().add(Duration(days: 14))
    ).then(
      (value) {
        events = _DataSource(value);
        setState(() {});
      },
    );
    // events = _DataSource([]);
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
    /* открыть окно с иформацией о предмете (название, время, адрес,
     препод, аудитория) */
    List<dynamic> res = details.appointments;
    if (res != null) {
      var result = res[0];
      print(result.subject + '. ' + result.notes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _drawerKey,
        drawer: HomeDrawer(),
        body: Stack(
          alignment: AlignmentDirectional.topStart,
          children: <Widget>[
            SfCalendar(
              view: viewType,
              dataSource: events,
              onTap: (CalendarTapDetails details) => openSubjectInfo(details),
              firstDayOfWeek: 1,
              appointmentTimeTextFormat: 'Hm',
              timeSlotViewSettings: TimeSlotViewSettings(
                timeFormat: 'Hm',
                startHour: 7,
                endHour: 22,
                timeTextStyle: timeTextStyle,
              ),
              viewHeaderStyle: ViewHeaderStyle(
                dateTextStyle: dateTextStyle,
                dayTextStyle: dateTextStyle,
              ),
              initialDisplayDate: DateTime.now(),
              todayHighlightColor: HexColor.fromHex('#1b5c94'),
              monthViewSettings: MonthViewSettings(),
              scheduleViewSettings: ScheduleViewSettings(
                appointmentTextStyle: mainStyle,
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
            ),
            IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  _drawerKey.currentState.openDrawer();
                }),
            Positioned(
                left: 60,
                child: IconButton(
                    icon: viewIcon,
                    onPressed: () {
                      switchView();
                    })),
          ],
        ),
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return BlocProvider(
                          create: (_) => GroupBloc(GroupSearchState.initial()),
                          child: SettingsPage(),
                        );
                      }),
                    );
                  }),
              ListTile(
                leading:
                    Icon(Icons.info_outline, size: 18, color: Colors.white),
                title: Text('Info',
                    style: drawerTextStyle.copyWith(fontSize: 19, height: .7)),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
