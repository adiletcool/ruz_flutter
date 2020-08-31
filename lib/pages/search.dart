import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:ruz/constants.dart';

import '../ruz.dart';

class Obj {
  // Group or Student
  final String name;
  final String id;
  const Obj(this.name, this.id);

  @override
  String toString() => 'Obj(name: $name, id: $id)';
}

class ObjSearch extends SearchDelegate<Obj> {
  final Bloc<ObjSearchEvent, ObjSearchState> groupBloc;
  final String searchType; // group / student

  ObjSearch(this.groupBloc, this.searchType);

  @override
  List<Widget> buildActions(BuildContext context) => null;

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: BackButtonIcon(),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    groupBloc.add(ObjSearchEvent(query, searchType));

    return BlocBuilder(
        cubit: groupBloc,
        builder: (context, state) {
          if (state.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (state.hasError) {
            return Container(child: Text('Error'));
          }

          return ListView.builder(
            itemCount: state.objects.length,
            itemBuilder: (context, index) {
              IconData leadingIcon = searchType == 'group'
                  ? MdiIcons.accountGroup
                  : MdiIcons.account;

              return ListTile(
                leading: Icon(leadingIcon, color: Colors.black),
                title: Text(state.objects[index].name, style: searchTextStyle),
                onTap: () => close(context, state.objects[index]),
              );
            },
          );
        });
  }

  Future _getSuggestions() async {
    return await getSearchSuggestion(query: query, type: searchType);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (((searchType == 'name') && (query.length >= 2)) ||
        (searchType == 'group')) {
      return FutureBuilder(
        future: _getSuggestions(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Obj> res = List.generate(snapshot.data.length, (index) {
              return Obj(
                snapshot.data[index]['label'],
                snapshot.data[index]['id'],
              );
            });

            return ListView.builder(
              itemCount: res.length,
              itemBuilder: (context, index) {
                IconData leadingIcon = searchType == 'group'
                    ? MdiIcons.accountGroup
                    : MdiIcons.account;
                return ListTile(
                  leading: Icon(leadingIcon, color: Colors.black),
                  title: Text(res[index].name, style: searchTextStyle),
                  onTap: () => close(context, res[index]),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Container();
          } else {
            return Center(child: Text('Nothing found'));
          }
        },
      );
    } else
      return Container();
  }
}

class ObjSearchEvent {
  final String query;
  final String searchType;
  const ObjSearchEvent(this.query, this.searchType);
}

class ObjSearchState {
  final bool isLoading;
  final List<Obj> objects;
  final bool hasError;

  const ObjSearchState({this.isLoading, this.objects, this.hasError});

  factory ObjSearchState.initial() {
    return ObjSearchState(objects: [], isLoading: false, hasError: false);
  }

  factory ObjSearchState.loading() {
    return ObjSearchState(objects: [], isLoading: true, hasError: false);
  }

  factory ObjSearchState.success(List<Obj> objects) {
    return ObjSearchState(objects: objects, isLoading: false, hasError: false);
  }

  factory ObjSearchState.error() {
    return ObjSearchState(objects: [], isLoading: false, hasError: true);
  }
}

class ObjBloc extends Bloc<ObjSearchEvent, ObjSearchState> {
  ObjBloc() : super(ObjSearchState.initial());

  @override
  Stream<ObjSearchState> mapEventToState(ObjSearchEvent event) async* {
    yield ObjSearchState.loading();

    try {
      List<Obj> objects =
          await _getSearchResults(event.query, event.searchType);
      yield ObjSearchState.success(objects);
    } catch (_) {
      yield ObjSearchState.error();
    }
  }

  Future<List<Obj>> _getSearchResults(String query, String searchType) async {
    var suggestions = await getSearchSuggestion(query: query, type: searchType);

    List<Obj> res = List.generate(suggestions.length, (index) {
      return Obj(suggestions[index]['label'], suggestions[index]['id']);
    });

    return res;
  }
}
