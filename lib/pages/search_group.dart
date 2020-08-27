import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:ruz/constants.dart';

import '../ruz.dart';

class Group {
  final String name;
  final String id;
  const Group(this.name, this.id);

  @override
  String toString() => 'Group(name: $name, id: $id)';
}

class GroupSearch extends SearchDelegate<Group> {
  final Bloc<GroupSearchEvent, GroupSearchState> groupBloc;
  GroupSearch(this.groupBloc);

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
    groupBloc.add(GroupSearchEvent(query));

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
              return ListTile(
                leading: Icon(MdiIcons.accountGroup, color: Colors.black),
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

class GroupSearchEvent {
  final String query;
  const GroupSearchEvent(this.query);
}

class GroupSearchState {
  final bool isLoading;
  final List<Group> groups;
  final bool hasError;

  const GroupSearchState({this.isLoading, this.groups, this.hasError});

  factory GroupSearchState.initial() {
    return GroupSearchState(groups: [], isLoading: false, hasError: false);
  }

  factory GroupSearchState.loading() {
    return GroupSearchState(groups: [], isLoading: true, hasError: false);
  }

  factory GroupSearchState.success(List<Group> groups) {
    return GroupSearchState(groups: groups, isLoading: false, hasError: false);
  }

  factory GroupSearchState.error() {
    return GroupSearchState(groups: [], isLoading: false, hasError: true);
  }
}

class GroupBloc extends Bloc<GroupSearchEvent, GroupSearchState> {
  GroupBloc() : super(GroupSearchState.initial());

  @override
  Stream<GroupSearchState> mapEventToState(GroupSearchEvent event) async* {
    yield GroupSearchState.loading();

    try {
      List<Group> groups = await _getSearchResults(event.query);
      yield GroupSearchState.success(groups);
    } catch (_) {
      yield GroupSearchState.error();
    }
  }

  Future<List<Group>> _getSearchResults(String query) async {
    var groupsFound = await getGroupSuggestion(query);

    List<Group> res = List.generate(groupsFound.length, (index) {
      return Group(groupsFound[index]['label'], groupsFound[index]['id']);
    });

    return res;
  }
}
