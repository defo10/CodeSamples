import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:selfhelper/model/db.dart';
import 'package:selfhelper/model/models.dart';

/// Viewmodel for the creator of a path, aka its author.
///
/// It also includes logic to load parts of the other paths of the specified
/// user.
class CreatorPathVM with ChangeNotifier {
  final int interval; // how many paths to load at a time
  final String uid;
  // document id to filter out. That is, the docid of the path calling
  // which shouldn't show up
  final String filterDocId;

  List<Path> _pathsOfCreator = [];
  List<Path> get pathsOfCreator => _pathsOfCreator;

  DocumentSnapshot _lastDoc; // the last fetched document

  Future<List<DocumentSnapshot>> _newestPaths;

  bool _hasMoreToCome = true;
  bool get hasMoreToCome => _hasMoreToCome;

  /// loads [interval] many path previews of [uid]'s paths
  CreatorPathVM(this.interval, this.uid, {this.filterDocId}) {
    loadMore(); // initial loading
  }

  /// loads more paths from this creator, [uid].
  loadMore() async {
    _newestPaths = (_lastDoc == null) // is called for first time?
        ? DatabaseService().getPathsOfCreator(uid, interval)
        : DatabaseService()
            .getPathsOfCreator(uid, interval, startAfter: _lastDoc);

    List<DocumentSnapshot> results = await _newestPaths;

    if (results.isEmpty) {
      _hasMoreToCome = false;
      return;
    }

    // not enough to fill interval, so that's the last interval
    if (results.length < interval) _hasMoreToCome = false;

    _lastDoc = results.last;
    Iterable<Path> loadedPaths = results
        .map((e) => Path.fromMap(e.data))
        .where((element) => element.id != filterDocId);

    pathsOfCreator.addAll(loadedPaths);
    notifyListeners();
  }
}
