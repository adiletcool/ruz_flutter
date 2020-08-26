import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ruz/HexColor.dart';
import 'package:ruz/constants.dart';
import 'package:ruz/pages/search_group.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedGroupVal = 'БМН 192';
  static const scheduleType = <String>['By group', 'By name'];
  static String selectedVal; // read from file
  List<DropdownMenuItem<String>> menuItems = scheduleType
      .map((String value) => DropdownMenuItem(
            child: Text(value, style: settingsTextStyle),
            value: value,
          ))
      .toList();

  @override
  void initState() {
    super.initState();
    selectedVal = 'By group';
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
                        setState(() {
                          selectedVal = newValue;
                        });
                      },
                      value: selectedVal,
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
    if (selectedVal == 'By group') {
      return Row(
        children: <Widget>[
          Text('Group: ', style: settingsTextStyle),
          Spacer(),
          Expanded(
              child: ListTile(
            title: Text(selectedGroupVal, style: settingsTextStyle),
            trailing: Icon(Icons.edit, color: Colors.white, size: 18),
            onTap: () async {
              Group selectedGroup = await showSearch(
                context: context,
                delegate: GroupSearch(BlocProvider.of<GroupBloc>(context)),
              );
              if (selectedGroup != null) {
                setState(() {
                  selectedGroupVal = selectedGroup.name;
                });
              }
            },
            contentPadding: EdgeInsets.only(left: 55),
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
            title:
                Text('Абираев Адилет Максатбекович', style: settingsTextStyle),
            trailing: Icon(Icons.edit, color: Colors.white, size: 18),
            onTap: () {
              print('Change name...');
            },
            contentPadding: EdgeInsets.only(left: 0),
          )),
        ],
      );
    }
  }
}
