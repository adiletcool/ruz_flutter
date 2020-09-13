import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:ruz/constants.dart';

class DeadlinePage extends StatefulWidget {
  final bool exists;
  final String currentList;
  final dateEnd;
  const DeadlinePage({this.exists, this.currentList, this.dateEnd});
  @override
  _DeadlinePageState createState() => _DeadlinePageState();
}

class _DeadlinePageState extends State<DeadlinePage> {
  String dateSet;

  @override
  void initState() {
    super.initState();
    dateSet = widget.dateEnd ?? 'Добавить дату';
  }

  Widget getMainBody() {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(widget.currentList, style: timeTextStyle),
                TextFormField(
                  autofocus: !widget.exists,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Новый дедлайн',
                  ),
                  style: TextStyle(fontSize: 22),
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                ),
                Divider(color: Colors.black),
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      flex: 1,
                      child: Icon(MdiIcons.textSubject,
                          size: 28, color: HexColor.fromHex('#33658a')),
                    ),
                    Flexible(
                      flex: 9,
                      child: TextFormField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Добавьте описание',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 10,
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
                      child: Icon(Icons.calendar_today,
                          color: HexColor.fromHex('#33658a')),
                    ),
                    SizedBox(width: 10),
                    FlatButton(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: HexColor.fromHex('#33658a')),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(dateSet,
                          style: TextStyle(
                              fontSize: 17,
                              color: HexColor.fromHex('#33658a'))),
                      onPressed: () {
                        showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                        ).then((DateTime value) {
                          if (value != null) {
                            dateSet = DateFormat("dd.MM.yyyy").format(value);
                            setState(() {});
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> appBarActions = widget.exists
        ? <Widget>[
            IconButton(
              icon: Icon(Icons.done, color: Colors.black),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.delete_sweep, color: Colors.black),
              onPressed: () {},
            ),
          ]
        : [
            FlatButton(
              child: Text('Сохранить',
                  style: TextStyle(
                      color: HexColor.fromHex('#33658a'), fontSize: 17)),
              onPressed: () {},
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
              icon: Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pushNamed(context, 'DeadlinesPage'),
            ),
          ),
          body: getMainBody(),
        ),
      ),
    );
  }
}
