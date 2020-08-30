import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ruz/constants.dart';
import 'search.dart';

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
  String selectedType = 'group'; // by default

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          flex: 3,
          child: Text(
            selectedType.capitalize() + ":",
            style: settingsTextStyle,
            overflow: TextOverflow.fade,
          ),
        ),
        Flexible(
            flex: 7,
            child: ListTile(
              title: Text(
                selectedType == 'group'
                    ? selectedGroupName
                    : selectedStudentName,
                maxLines: 2,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: settingsTextStyle.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
              trailing: Icon(Icons.edit, color: Colors.white, size: 18),
              contentPadding: setLeftPaddingForGroup(),
              onTap: () async {
                Obj selectedValue = await showSearch(
                  context: context,
                  delegate: ObjSearch(
                      BlocProvider.of<ObjBloc>(context), selectedType),
                );

                if (selectedValue != null) {
                  setState(() {
                    if (selectedType == 'group') {
                      selectedGroupName = selectedValue.name;
                      selectedGroupId = selectedValue.id;
                    } else {
                      selectedStudentName = selectedValue.name;
                      selectedStudentId = selectedValue.id;
                    }
                  });
                  _saveSettings();
                }
              },
            )),
      ],
    );
  }

  EdgeInsets setLeftPaddingForGroup() {
    List words = selectedGroupName.split(' ');
    if (words.length > 1)
      return EdgeInsets.only(left: 0);
    else
      return EdgeInsets.only(left: 40);
  }
}
