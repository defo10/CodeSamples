import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:selfhelper/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

class DatabaseService {
  static final Firestore _firedb = Firestore.instance;
  static final DatabaseService _instance = DatabaseService._internal();
  // shared preferences keys
  static const _keyLastUpdatedNewestPaths = 'newestPathsLastUpdated',
      _keyLastUpdatedChosenPath = 'lastUpdatedChosenPath',
      _keyChosenPathDocId = 'chosenPathDocId',
      _keyChosenPathUid = 'chosenPathUid',
      _keyChosenPathMorningReminder = 'chosenPathMorningReminder',
      _keyChosenPathNoonReminder = 'chosenPathNoonReminder',
      _keyChosenPathEveningReminder = 'chosenPathEveningReminder',
      _keyChosenPathNumReminders = 'chosenPathNumReminders',
      _keyTimesReminders = 'timesReminders';
  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();
  static final Future<Database> _sqldb = openDatabase('whatareyoulookingfor.db',
      onCreate: (Database db, int vers) async {
    await db.execute('CREATE TABLE PathHistory ('
        'docid TEXT,'
        'uid TEXT,'
        'datepicked INTEGER,'
        'PRIMARY KEY (docid, uid)'
        ')');
    await db.execute('CREATE TABLE ChaptersRead ('
        'docid TEXT,'
        'uid TEXT,'
        'chapterindex INTEGER,'
        'PRIMARY KEY (docid, uid, chapterindex)'
        ')');
  }, version: 1);

  factory DatabaseService() => _instance;

  DatabaseService._internal() {
    // 40 MB (as is default)
    _firedb.settings(
        persistenceEnabled: true, cacheSizeBytes: 40 * 1000 * 1000);
    timesReminder.then((List<TimeOfDay> timesReminder) {
      // default times
      if (timesReminder == null)
        setTimesReminder(
            morning: TimeOfDay(hour: 9, minute: 0),
            noon: TimeOfDay(hour: 15, minute: 0),
            evening: TimeOfDay(hour: 21, minute: 0));
    });
  }

  /// returns 20 newest paths.
  Future<List<Path>> getNewestPaths() async {
    try {
      SharedPreferences prefs = await _prefs;
      DateTime lastUpdate = DateTime.parse(
          prefs.getString(_keyLastUpdatedNewestPaths) ??
              '1900-01-01 00:00:00.000');
      DateTime now = DateTime.now();

      List<DocumentSnapshot> documents = await _checkDocsOfflineThenOnline(
          _firedb
              .collection('snippets')
              .orderBy('publishedOn', descending: true)
              .limit(20),
          now.difference(lastUpdate).inHours < 6);

      List<Path> paths =
          documents.map((doc) => Path.fromMap(doc.data)).toList();

      prefs.setString(_keyLastUpdatedNewestPaths, now.toString());
      return (paths);
    } catch (err) {
      throw err;
    }
  }

  /// returns [size] paths of [uid].
  ///
  /// [startsAfter] is used for pagination. All documents up until [startAfter]
  /// (inclusive) will be skipped and the returned list.
  Future<List<DocumentSnapshot>> getPathsOfCreator(String uid, int size,
      {DocumentSnapshot startAfter}) async {
    try {
      Query query;
      if (startAfter != null) {
        // consecutive reads
        query = _firedb
            .collection('snippets')
            .where('uid', isEqualTo: uid)
            .orderBy('publishedOn', descending: true)
            .limit(size)
            .startAfterDocument(startAfter);
      } else {
        // first read
        query = _firedb
            .collection('snippets')
            .where('uid', isEqualTo: uid)
            .orderBy('publishedOn', descending: true)
            .limit(size);
      }

      QuerySnapshot querySnapshot = await query.getDocuments();
      List<DocumentSnapshot> documents = querySnapshot.documents;
      return documents;
    } catch (err) {
      throw err;
    }
  }

  Future<bool> _deleteSharedPrefsChosenPath() async {
    SharedPreferences prefs = await _prefs;
    await prefs.remove(_keyChosenPathUid);
    await prefs.remove(_keyChosenPathDocId);
    return prefs.remove(_keyLastUpdatedChosenPath);
  }

  /// checks the cache for _documents_ satisfying to [queryWOgetDocs] in
  /// if [cacheFirst], else checks online right away, and returns the
  /// [List<DocumentSnapshot>] or null if non-existent.
  ///
  /// [queryWOgetDocs] stands for query without getDocs, where getDocs stands
  /// for the .getDocuments() method used to retrieve the documents. This is
  /// appended by this method, so the source (server/cache) can be changed.
  ///
  /// [cacheFirst] indicates that first the cache should be checked which
  /// has no costs associated with it, at the cost of potentially not being
  /// up to date.
  ///
  /// see also:
  ///   * [_checkOfflineThenOnline] which does the same but only with one
  ///   document
  Future<List<DocumentSnapshot>> _checkDocsOfflineThenOnline(
      Query queryWOgetDocs, bool cacheFirst) async {
    QuerySnapshot querySnapshot;
    Source cacheOrServer = cacheFirst ? Source.cache : Source.server;
    try {
      querySnapshot = await queryWOgetDocs.getDocuments(source: cacheOrServer);
    } catch (err) {
      if (cacheOrServer == Source.server) {
        // documents exist neither off- nor online, so was deleted from creator
        return null;
      }
      // if not locally, check online
      querySnapshot = await queryWOgetDocs.getDocuments(source: Source.server);
    }
    return querySnapshot.documents;
  }

  /// checks the cache for the document in [pathToDocument] if [cacheFirst],
  /// else checks online right away, and returns the [DocumentSnapshot].
  ///
  /// [cacheFirst] indicates that first the cache should be checked which
  /// has no costs associated with it, at the cost of potentially not being
  /// up to date.
  ///
  /// see also:
  ///   *  [_checkDocsOfflineThenOnline] which checks for multiple documents
  Future<DocumentSnapshot> _checkOfflineThenOnline(
      String pathToDocument, bool cacheFirst) async {
    DocumentSnapshot pathDocument;
    Source cacheOrServer = cacheFirst ? Source.cache : Source.server;
    // not my proudest code... firebase throws an exception if source is set
    // as cache
    try {
      pathDocument =
          await _firedb.document(pathToDocument).get(source: cacheOrServer);
    } catch (err) {
      if (cacheOrServer == Source.server) {
        // documents exists neither off- nor online, so was deleted from creator
        return null;
      }
      // if not locally, check online
      pathDocument =
          await _firedb.document(pathToDocument).get(source: Source.server);
      if (!pathDocument.exists) {
        return null;
      }
    }
    return pathDocument;
  }

  /// returns chosen path or null iff no path was chosen.
  ///
  /// The method checks the shared preferences for the chosen path doc id and
  /// path uid. If no id is found, i.e. the user has no path chosen yet,
  /// null is returned.
  ///
  /// Null is also returned when the document doesn't exist, e.g. when the
  /// creator deleted the document in the meantime.
  ///
  /// If you wish to set the path, you have to set the corresponding shared
  /// preference keys, e.g. by calling [setChosenPathsSharedPrefs], and then
  /// call this method.
  Future<Path> getChosenPath() async {
    try {
      SharedPreferences prefs = await _prefs;

      String docid = prefs.getString(_keyChosenPathDocId);
      String uid = prefs.getString(_keyChosenPathUid);
      if (docid == null || uid == null) return null;

      DateTime lastUpdated = DateTime.parse(
              prefs.getString(_keyLastUpdatedChosenPath) ??
                  '1900-01-01 00:00:00.000'),
          now = DateTime.now();

      DocumentSnapshot pathDocument = await _checkOfflineThenOnline(
          'users/' + uid + '/paths/' + docid,
          now.difference(lastUpdated).inDays <= 7);

      if (pathDocument == null) {
        // document doesnt exist
        await _deleteSharedPrefsChosenPath();
        return null;
      }

      Path path = Path.fromMap(pathDocument.data);
      await prefs.setString(_keyLastUpdatedChosenPath, now.toString());
      await prefs.setString(_keyChosenPathDocId, path.id);
      await prefs.setString(_keyChosenPathUid, path.uid);

      return (path);
    } catch (err) {
      throw err;
    }
  }

  /// saves the chosen path credentials [uid], [docid] and time preferences in
  /// the shared preferences.
  ///
  /// It can then accessed through [getChosenPath]. [uid] is the user id of the
  /// path's creator. [docid] is the document id uniquely identifying the path.
  Future<bool> setChosenPathsSharedPrefs(
      String uid,
      String docid,
      bool morningReminder,
      bool noonReminder,
      bool eveningReminder,
      int numReminderPerDay) async {
    try {
      SharedPreferences prefs = await _prefs;
      bool first = await prefs.setString(_keyChosenPathUid, uid);
      bool second = await prefs.setString(_keyChosenPathDocId, docid);
      bool third =
          await prefs.setBool(_keyChosenPathMorningReminder, morningReminder);
      bool forth =
          await prefs.setBool(_keyChosenPathNoonReminder, noonReminder);
      bool fifth =
          await prefs.setBool(_keyChosenPathEveningReminder, eveningReminder);
      bool sixth =
          await prefs.setInt(_keyChosenPathNumReminders, numReminderPerDay);
      return first && second && third && forth && fifth && sixth;
    } catch (err) {
      throw err;
    }
  }

  /// inserts record to the PathHistory table of the database.
  ///
  /// This is used to give the user a history of his paths. The current time
  /// is used as the 'datepicked' column entry of the table.
  Future<int> insertPathHistory(String uid, String docid) async {
    Database db = await _sqldb;
    return db.insert('PathHistory', {
      'uid': uid,
      'docid': docid,
      'datepicked': DateTime.now().millisecondsSinceEpoch
    });
  }

  /// inserts a row into the ChaptersRead table of the database.
  ///
  /// [chapterIndex] is the index of the chapter in the path which was read.
  Future<int> insertChapterRead(
      String uid, String docid, int chapterIndex) async {
    Database db = await _sqldb;
    try {
       int result = await db.insert('ChaptersRead',
          {'uid': uid, 'docid': docid, 'chapterindex': chapterIndex});
       NotificationsManager().scheduleNotifications(await getChosenPath());
       return result;
    } catch (DatabaseException) {
      // this happens in the form of an SQLITE_CONSTRAINT_PRIMARYKEY trying to
      // insert if entry already exists
      NotificationsManager().scheduleNotifications(await getChosenPath());
      return 1;
    }
  }

  /// returns a list of indices showing which chapter was read.
  Future<List<int>> getReadChapters(String uid, String docid) async {
    Database db = await _sqldb;
    List<Map> results = await db.query('ChaptersRead',
        columns: ['chapterindex'],
        where: 'uid = ? AND docid = ?',
        whereArgs: [uid, docid],
        orderBy: 'chapterindex ASC');
    return [for (Map row in results) row['chapterindex']];
  }

  /// returns a list of indices showing which chapter was read of the chosen path.
  ///
  /// This function is a convenience function over [getReadChapters]. The uid
  /// and docid are taken from the respective shared preference key.
  Future<List<int>> getReadChaptersChosenPath() async {
    SharedPreferences prefs = await _prefs;
    String uid = prefs.getString(_keyChosenPathUid);
    String docid = prefs.getString(_keyChosenPathDocId);

    if (uid == null || docid == null) throw Error();

    return getReadChapters(uid, docid);
  }

  Future<bool> get morningReminder async {
    SharedPreferences prefs = await _prefs;
    return prefs.getBool(_keyChosenPathMorningReminder);
  }

  setMorningReminder(bool allowed, {Path path}) async {
    SharedPreferences prefs = await _prefs;
    prefs.setBool(_keyChosenPathMorningReminder, allowed);
    NotificationsManager().scheduleNotifications(path ?? await getChosenPath());
  }

  Future<bool> get noonReminder async {
    SharedPreferences prefs = await _prefs;
    return prefs.getBool(_keyChosenPathNoonReminder);
  }

  setNoonReminder(bool allowed, {Path path}) async {
    SharedPreferences prefs = await _prefs;
    prefs.setBool(_keyChosenPathNoonReminder, allowed);
    NotificationsManager().scheduleNotifications(path ?? await getChosenPath());
  }

  Future<bool> get eveningReminder async {
    SharedPreferences prefs = await _prefs;
    return prefs.getBool(_keyChosenPathEveningReminder);
  }

  setEveningReminder(bool allowed, {Path path}) async {
    SharedPreferences prefs = await _prefs;
    await prefs.setBool(_keyChosenPathEveningReminder, allowed);
    NotificationsManager().scheduleNotifications(path ?? await getChosenPath());
  }

  Future<int> get numRemindersPerDay async {
    SharedPreferences prefs = await _prefs;
    return prefs.getInt(_keyChosenPathNumReminders);
  }

  setNumRemindersPerDay(int num, {Path path}) async {
    SharedPreferences prefs = await _prefs;
    await prefs.setInt(_keyChosenPathNumReminders, num);
    NotificationsManager().scheduleNotifications(path ?? await getChosenPath());
  }

  /// returns list of three TimeOfDay objects indicating at what exact time the
  /// reminder should be scheduled.
  ///
  /// List has this form [TimeOfDay morning, TimeOfDay noon, TimeOfDay evening]
  Future<List<TimeOfDay>> get timesReminder async {
    SharedPreferences prefs = await _prefs;
    return prefs
        .getStringList(_keyTimesReminders)
        .map((e) => TimeOfDay(
            hour: int.parse(e.split(':')[0]),
            minute: int.parse(e.split(':')[1])))
        .toList();
  }

  /// sets when user should get reminders
  setTimesReminder(
      {@required TimeOfDay morning,
      @required TimeOfDay noon,
      @required TimeOfDay evening,
      Path path}) async {
    SharedPreferences prefs = await _prefs;
    await prefs.setStringList(_keyTimesReminders, [
      '${morning.hour}:${morning.minute}',
      '${noon.hour}:${noon.minute}',
      '${evening.hour}:${evening.minute}',
    ]);
    NotificationsManager().scheduleNotifications(path ?? await getChosenPath());
  }
}
