import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../ruz.dart';

class Group {
  final String name;
  const Group(this.name);

  @override
  String toString() => name;
}

class GroupSearch extends SearchDelegate<Group> {
  final Bloc<GroupSearchEvent, GroupSearchState> groupBloc;
  GroupSearch(this.groupBloc);

  @override
  List<Widget> buildActions(BuildContext context) => null;

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        icon: BackButtonIcon(), onPressed: () => close(context, null));
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
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(Icons.group),
                title: Text(state.groups[index].name),
                onTap: () => close(context, state.groups[index]),
              );
            },
            itemCount: state.groups.length,
          );
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) => Container();
}

class GroupSearchEvent {
  final String query;
  const GroupSearchEvent(this.query);
  @override
  String toString() => 'GroupSearchEvent { query: $query }';
}

class GroupSearchState {
  final bool isLoading;
  final List<Group> groups;
  final bool hasError;

  const GroupSearchState({this.isLoading, this.groups, this.hasError});

  factory GroupSearchState.initial() {
    return GroupSearchState(
      groups: [],
      isLoading: false,
      hasError: false,
    );
  }

  factory GroupSearchState.loading() {
    return GroupSearchState(
      groups: [],
      isLoading: true,
      hasError: false,
    );
  }

  factory GroupSearchState.success(List<Group> groups) {
    return GroupSearchState(
      groups: groups,
      isLoading: false,
      hasError: false,
    );
  }

  factory GroupSearchState.error() {
    return GroupSearchState(
      groups: [],
      isLoading: false,
      hasError: true,
    );
  }

  @override
  String toString() {
    return 'GroupSearchState {cities: ${groups.toString()}, isLoading: $isLoading, hasError: $hasError }';
  }
}

class GroupBloc extends Bloc<GroupSearchEvent, GroupSearchState> {
  GroupBloc(GroupSearchState initialState) : super(initialState);

  @override
  Stream<GroupSearchState> mapEventToState(GroupSearchEvent event) async* {
    yield GroupSearchState.loading();

    try {
      List<Group> cities = await _getSearchResults(event.query);
      yield GroupSearchState.success(cities);
    } catch (_) {
      yield GroupSearchState.error();
    }
  }

  Future<List<Group>> _getSearchResults(String query) async {
    // Simulating network latency
    var groupsFound = await getGroupSuggestion(query);
    print(groupsFound);

    List<Group> res = List.generate(groupsFound.length, (index) {
      return Group(groupsFound[index]['groupName']); // key????
    });

    print(res);
    // return res;

    return [Group('БМН 177')];
  }
}
