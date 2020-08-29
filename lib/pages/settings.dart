import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ruz/constants.dart';
import 'package:ruz/pages/search_group.dart';
import 'search_student.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedGroupName = '';
  String selectedGroupId = '';
  String selectedStudentName = '';
  String selectedStudentId = '';

  static const scheduleType = <String>['group', 'name'];
  static String selectedType;

  List<DropdownMenuItem<String>> menuItems = scheduleType
      .map((String value) => DropdownMenuItem(
            child: Text('By $value', style: settingsTextStyle),
            value: value,
          ))
      .toList();

  @override
  void initState() {
    super.initState();
    // read from file (List<String> см NotesApp)
    // clearSettigns();
    getSettings().then((res) {
      setState(() {
        selectedType = res['selectedType'] ?? 'group';
        selectedGroupName = res['selectedGroupName'] ?? 'Find your group';
        selectedGroupId = res['selectedGroupId'] ?? '';
        selectedStudentName = res['selectedStudentName'] ?? 'Find your name';
        selectedStudentId = res['selectedStudentId'] ?? '';
      });
    });
  }

  void _saveSettings() {
    saveSettings(
      selectedType,
      selectedGroupName,
      selectedGroupId,
      selectedStudentName,
      selectedStudentId,
    );
  }

  void goBackHome() {
    Navigator.pushNamed(context, 'HomePage');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        goBackHome();
        return;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
              title: Text('Settings', style: mainStyle),
              backgroundColor: Colors.black87,
              elevation: 1,
              leading: IconButton(
                  icon:
                      Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: () => goBackHome())),
          body: CustomScrollView(
            slivers: <Widget>[
              SliverFillRemaining(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  color: HexColor.fromHex('#1A2026'),
                  child: Column(
                    children: <Widget>[
                      Row(children: <Widget>[
                        Text('Schedule: ', style: settingsTextStyle),
                        Spacer(),
                        DropdownButton(
                          dropdownColor: Colors.grey,
                          elevation: 1,
                          items: menuItems,
                          onChanged: (String newValue) {
                            setState(() => selectedType = newValue);
                            _saveSettings();
                          },
                          value: selectedType,
                        ),
                      ]),
                      SizedBox(height: 20),
                      Divider(color: Colors.white),
                      SizedBox(height: 20),
                      getSettingsWidget(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget getSettingsWidget() {
    if (selectedType == 'group') {
      return Row(
        children: <Widget>[
          Text('Group: ', style: settingsTextStyle),
          Spacer(flex: 2),
          Expanded(
              flex: 3,
              child: ListTile(
                title: Text(selectedGroupName,
                    maxLines: 1,
                    style: settingsTextStyle.copyWith(
                      decoration: TextDecoration.underline,
                    )),
                trailing: Icon(Icons.edit, color: Colors.white, size: 18),
                contentPadding: setLeftPaddingForGroup(),
                onTap: () async {
                  Group selectedGroup = await showSearch(
                    context: context,
                    delegate: GroupSearch(BlocProvider.of<GroupBloc>(context)),
                  );

                  if (selectedGroup != null) {
                    setState(() {
                      selectedGroupName = selectedGroup.name;
                      selectedGroupId = selectedGroup.id;
                    });
                    _saveSettings();
                  }
                },
              )),
        ],
      );
    } else {
      return Row(
        children: <Widget>[
          Text('Name: ', style: settingsTextStyle),
          Spacer(flex: 2),
          Expanded(
              flex: 3,
              child: ListTile(
                title: Text(
                  selectedStudentName,
                  maxLines: 1,
                  style: settingsTextStyle.copyWith(
                      decoration: TextDecoration.underline),
                ),
                trailing: Icon(Icons.edit, color: Colors.white, size: 18),
                contentPadding: EdgeInsets.only(left: 0),
                onTap: () async {
                  Student selectedName = await showSearch(
                    context: context,
                    delegate:
                        StudentSearch(BlocProvider.of<StudentBloc>(context)),
                  );

                  if (selectedName != null) {
                    setState(() {
                      selectedStudentName = selectedName.name;
                      selectedStudentId = selectedName.id;
                    });
                    _saveSettings();
                  }
                },
              )),
        ],
      );
    }
  }

  EdgeInsets setLeftPaddingForGroup() {
    List words = selectedGroupName.split(' ');
    if (words.length > 1)
      return EdgeInsets.only(left: 0);
    else
      return EdgeInsets.only(left: 40);
  }
}
