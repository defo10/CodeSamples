import 'package:flutter/material.dart';
import 'package:selfhelper/model/db.dart';
import 'package:selfhelper/model/models.dart' as model;

/// The [Model.Path] chosen by the user.
class ChosenPath with ChangeNotifier {
  Future<model.Path> chosenPath = DatabaseService().getChosenPath();

  /// tries to fetch the chosen path.
  /// Returns a reference to the chosen path, null if not path was chosen yet.
  initialSync() async {
    return await chosenPath;
    // if path was chosen
  }

  ChosenPath() {
    initialSync();
  }

  /// sets the chosen path and its preferences in the persistent shared
  /// preferences, then synchronizes the [chosenPath] that notifies all
  /// listeners of the change.
  ///
  /// [uid] is the user id of the path creator
  /// [docid] is the document id of the path creator
  /// [morningReminder] tells if should user be reminded in the morning
  /// [noonReminder] tells if should user be reminded in the noon
  /// [eveningReminder] tells if should user be reminded in the evening
  /// [numReminderPerDay] tells how many reminders user wishes to receive at most
  updateChosenPath(String uid, String docid, bool morningReminder,
      bool noonReminder, bool eveningReminder, int numReminderPerDay) async {

    bool hasSaved = await DatabaseService().setChosenPathsSharedPrefs(uid, docid,
        morningReminder, noonReminder, eveningReminder, numReminderPerDay);

    if (!hasSaved) throw Error();

    chosenPath = DatabaseService().getChosenPath();
    notifyListeners();
  }
}