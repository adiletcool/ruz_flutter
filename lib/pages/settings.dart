import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ruz/HexColor.dart';
import 'package:ruz/constants.dart';
import 'package:ruz/pages/search_group.dart';

import 'search_student.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedGroupVal;
  String selectedGroupId; // read from file
  String selectedStudentName;
  String selectedStudentId;

  static const scheduleType = <String>['By group', 'By name'];
  static String selectedType;

  List<DropdownMenuItem<String>> menuItems = scheduleType
      .map((String value) => DropdownMenuItem(
            child: Text(value, style: settingsTextStyle),
            value: value,
          ))
      .toList();

  @override
  void initState() {
    super.initState();
    // read from file (List<String> см NotesApp)
    selectedType = 'By group';
    selectedGroupVal = 'БМН 192';
    selectedGroupId = '';
    selectedStudentName = 'Абираев Адилет Максатбекович';
    selectedStudentId = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: mainStyle),
        backgroundColor: Colors.black87,
        elevation: 1,
      ),
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
                      },
                      value: selectedType,
                    ),
                  ]),
                  SizedBox(height: 20),
                  Divider(color: Colors.white),
                  SizedBox(height: 20),
                  getSettings(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget getSettings() {
    if (selectedType == 'By group') {
      return Row(
        children: <Widget>[
          Text('Group: ', style: settingsTextStyle),
          Spacer(),
          Expanded(
              child: ListTile(
            title: Text(selectedGroupVal, style: settingsTextStyle),
            trailing: Icon(Icons.edit, color: Colors.white, size: 18),
            contentPadding: EdgeInsets.only(left: 40),
            onTap: () async {
              Group selectedGroup = await showSearch(
                context: context,
                delegate: GroupSearch(BlocProvider.of<GroupBloc>(context)),
              );

              if (selectedGroup != null) {
                setState(() {
                  selectedGroupVal = selectedGroup.name;
                  selectedGroupId = selectedGroup.id;
                });
              }
            },
          )),
        ],
      );
    } else {
      return Row(
        children: <Widget>[
          Text('Name: ', style: settingsTextStyle),
          SizedBox(width: 150),
          Expanded(
              child: ListTile(
            title: Text(selectedStudentName, style: settingsTextStyle),
            trailing: Icon(Icons.edit, color: Colors.white, size: 18),
            contentPadding: EdgeInsets.only(left: 0),
            onTap: () async {
              Student selectedName = await showSearch(
                context: context,
                delegate: StudentSearch(BlocProvider.of<StudentBloc>(context)),
              );

              if (selectedName != null) {
                setState(() {
                  selectedStudentName = selectedName.name;
                  selectedStudentId = selectedName.id;
                });
              }
            },
          )),
        ],
      );
    }
  }
}
