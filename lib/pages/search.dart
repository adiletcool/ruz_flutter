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
            itemCount: state.groups.length,
            itemBuilder: (context, index) {
              IconData leadingIcon = searchType == 'group'
                  ? MdiIcons.accountGroup
                  : MdiIcons.account;

              return ListTile(
                leading: Icon(leadingIcon, color: Colors.black),
                title: Text(state.groups[index].name, style: searchTextStyle),
                onTap: () => close(context, state.groups[index]),
              );
            },
          );
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) => Container();
}

class ObjSearchEvent {
  final String query;
  final String searchType;
  const ObjSearchEvent(this.query, this.searchType);
}

class ObjSearchState {
  final bool isLoading;
  final List<Obj> groups;
  final bool hasError;

  const ObjSearchState({this.isLoading, this.groups, this.hasError});

  factory ObjSearchState.initial() {
    return ObjSearchState(groups: [], isLoading: false, hasError: false);
  }

  factory ObjSearchState.loading() {
    return ObjSearchState(groups: [], isLoading: true, hasError: false);
  }

  factory ObjSearchState.success(List<Obj> groups) {
    return ObjSearchState(groups: groups, isLoading: false, hasError: false);
  }

  factory ObjSearchState.error() {
    return ObjSearchState(groups: [], isLoading: false, hasError: true);
  }
}

class ObjBloc extends Bloc<ObjSearchEvent, ObjSearchState> {
  ObjBloc() : super(ObjSearchState.initial());

  @override
  Stream<ObjSearchState> mapEventToState(ObjSearchEvent event) async* {
    yield ObjSearchState.loading();

    try {
      List<Obj> groups = await _getSearchResults(event.query, event.searchType);
      yield ObjSearchState.success(groups);
    } catch (_) {
      yield ObjSearchState.error();
    }
  }

  Future<List<Obj>> _getSearchResults(String query, String searchType) async {
    var groupsFound = searchType == 'group'
        ? await getGroupSuggestion(query)
        : await getStudentNameSuggestion(query);

    List<Obj> res = List.generate(groupsFound.length, (index) {
      return Obj(groupsFound[index]['label'], groupsFound[index]['id']);
    });

    return res;
  }
}
