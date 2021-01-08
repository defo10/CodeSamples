import 'package:flutter/material.dart';
import 'package:selfhelper/model/db.dart';
import 'package:selfhelper/model/models.dart' as model;
import 'package:selfhelper/notifications.dart';

/// Keeps track of read chapters and schedules notifications on every
/// chapter read.
class ChaptersVM with ChangeNotifier {
  final model.Path path;
  final String docid; // the id of the path

  Future<List<int>> _chaptersRead;
  /// Reads read chapters of corresponding [model.Path] and returns list of
  /// indices of those read.
  /// Also schedules notifications.
  Future<List<int>> get chaptersRead {
    NotificationsManager().scheduleNotifications(path);
    if (_chaptersRead == null) {
      _chaptersRead = DatabaseService().getReadChapters(path.uid, docid);
      return _chaptersRead;
    }
    return _chaptersRead;
  }

  /// adds [chapterIndex] to the list of chapters read for that [model.Path].
  /// Notifies all listeners of that change.
  updateChaptersRead(chapterIndex) async {
    await DatabaseService().insertChapterRead(path.uid, docid, chapterIndex);
    _chaptersRead = DatabaseService().getReadChapters(path.uid, docid);
    notifyListeners();
  }

  ChaptersVM(this.path, this.docid);
}