library scaffold_list;

import 'dart:async';

import 'package:flutter/material.dart' hide showSearch;
import 'package:flutter/material.dart' as Default show showSearch;

typedef SearchedFilter<T> = bool Function(T, String);
typedef FilterdList<T> = bool Function(T);
typedef SortedList<T> = int Function(T, T);
typedef TypedWidgetBuilder<T> = Widget Function(BuildContext, T);
typedef TypedIndexWidgetBuilder<T> = Widget Function(BuildContext, T, int);

class ScaffoldListView<T> extends ListView {
  ScaffoldListView({
    Key key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry padding,
    TypedWidgetBuilder<T> itemBuilder,
    TypedIndexWidgetBuilder<T> itemBuilderWithIndex,
    IndexedWidgetBuilder separatorBuilder,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double cacheExtent,
    List<T> list,
  })  : assert(list != null),
        super.separated(
          key: key,
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          itemBuilder: (BuildContext context, int index) {
            if (itemBuilder != null) {
              return itemBuilder(context, list[index]);
            } else {
              return itemBuilderWithIndex(context, list[index], index);
            }
          },
          separatorBuilder: (BuildContext context, int index) =>
              separatorBuilder != null
                  ? separatorBuilder(context, index)
                  : SizedBox(),
          itemCount: list.length,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          cacheExtent: cacheExtent,
        );
}

class ScaffoldListStyle {
  const ScaffoldListStyle({
    this.error = const Center(child: Text('Oops, something went wrong')),
    this.loading = const Center(child: CircularProgressIndicator()),
    this.empty = const Center(child: Text('Empty List')),
    this.noResults = const Center(child: Text('No Results')),
  });

  final Widget error, loading, empty, noResults;
}

class ScaffoldList<T> extends StatefulWidget {
  ScaffoldList({
    Key key,
    this.list,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.itemBuilder,
    this.itemBuilderWithIndex,
    this.separatorBuilder,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.filter,
    this.sort,
    this.searchFilter,
    this.searchDelegate,
    this.searchHintText,
    this.searchTheme,
    this.style = const ScaffoldListStyle(),
  })  : assert(searchDelegate != null ? searchFilter != null : true),
        assert(itemBuilder != null || itemBuilderWithIndex != null),
        super(key: key);

  final dynamic list;

  final Axis scrollDirection;
  final bool reverse;
  final ScrollController controller;
  final bool primary;
  final ScrollPhysics physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double cacheExtent;

  final FilterdList<T> filter;
  final SortedList<T> sort;
  final TypedWidgetBuilder<T> itemBuilder;
  final TypedIndexWidgetBuilder<T> itemBuilderWithIndex;
  final IndexedWidgetBuilder separatorBuilder;
  final SearchedFilter<T> searchFilter;
  final SearchDelegate searchDelegate;
  final String searchHintText;
  final ThemeData searchTheme;

  final ScaffoldListStyle style;

  @override
  ScaffoldListState<T> createState() => ScaffoldListState<T>();
}

class ScaffoldListState<T> extends State<ScaffoldList<T>> {
  List<T> _list = [];

  List<T> get list => _list;

  Future<T> showSearch() async => await Default.showSearch<T>(
        context: context,
        delegate: widget.searchDelegate ??
            ScaffoldListSearchDelegate<T>(
              list: _list,
              itemBuilder: (BuildContext context, T type) {
                if (widget.itemBuilder != null) {
                  return widget.itemBuilder(context, type);
                } else {
                  return widget.itemBuilderWithIndex(context, type, null);
                }
              },
              filter: widget.searchFilter,
              style: widget.style,
              hintText: widget.searchHintText,
              theme: widget.searchTheme,
            ),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.list is Stream<List<T>>) {
      return StreamBuilder<List<T>>(
        stream: widget.list,
        builder: (BuildContext context, AsyncSnapshot<List<T>> snapshot) =>
            _build(
          isLoading: snapshot.connectionState == ConnectionState.waiting,
          hasError: snapshot.hasError,
          list: snapshot.data,
        ),
      );
    } else if (widget.list is Future<List<T>>) {
      return FutureBuilder<List<T>>(
        future: widget.list,
        builder: (BuildContext context, AsyncSnapshot<List<T>> snapshot) =>
            _build(
          isLoading: snapshot.connectionState == ConnectionState.waiting,
          hasError: snapshot.hasError,
          list: snapshot.data,
        ),
      );
    } else if (widget.list is List<T>) {
      return _build(isLoading: false, list: widget.list);
    } else if (widget.list == null) {
      return _build(isLoading: true);
    } else {
      return ErrorWidget(
        'type ${widget.list.runtimeType} is not subtype of Stream<List<T>>, Future<List<$T>> or List<$T>',
      );
    }
  }

  Widget _build({
    bool isLoading,
    bool hasError = false,
    List<T> list,
  }) {
    if (hasError) {
      return _buildError();
    } else if (isLoading) {
      return _buildLoading();
    } else {
      if (widget.filter != null) {
        list = list.where(widget.filter).toList();
      }
      if (widget.sort != null) {
        list = list..sort(widget.sort);
      }
      return list.isEmpty ? _buildEmpty() : _buildList(list);
    }
  }

  Widget _buildError() => widget.style.error;

  Widget _buildLoading() => widget.style.loading;

  Widget _buildEmpty() =>
      widget.searchFilter == null ? widget.style.noResults : widget.style.empty;

  Widget _buildList(List<T> list) => ScaffoldListView<T>(
        list: _list = list,
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        controller: widget.controller,
        primary: widget.primary,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        padding: widget.padding,
        itemBuilder: widget.itemBuilder,
        itemBuilderWithIndex: widget.itemBuilderWithIndex,
        separatorBuilder: widget.separatorBuilder,
        addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.addRepaintBoundaries,
        addSemanticIndexes: widget.addSemanticIndexes,
        cacheExtent: widget.cacheExtent,
      );
}

class ScaffoldListSearchDelegate<T> extends SearchDelegate<T> {
  ScaffoldListSearchDelegate({
    this.list,
    this.itemBuilder,
    this.filter,
    this.style,
    this.hintText,
    this.theme,
  }) : super(searchFieldLabel: hintText);

  @override
  ThemeData appBarTheme(BuildContext context) =>
      this.theme ?? super.appBarTheme(context);

  final List<T> list;
  final TypedWidgetBuilder<T> itemBuilder;
  final SearchedFilter<T> filter;
  final ScaffoldListStyle style;

  final String hintText;
  final ThemeData theme;

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) => ScaffoldList<T>(
        list: list,
        filter: (T item) => filter != null
            ? filter(item, query)
            : item.toString().startsWith(query.toString()),
        itemBuilder: itemBuilder,
      );

  @override
  List<Widget> buildActions(BuildContext context) => <Widget>[
        IconButton(
          tooltip: query.isEmpty
              ? MaterialLocalizations.of(context).closeButtonTooltip
              : 'Clear',
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (query.isEmpty) {
              close(context, null);
            } else {
              query = '';
              showSuggestions(context);
            }
          },
        ),
      ];
}
