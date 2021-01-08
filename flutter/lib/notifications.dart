import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:selfhelper/android/main.dart';
import 'package:selfhelper/android/onlyfadepagerouter.dart';
import 'package:selfhelper/android/path/chapters/chapter_expanded_screen.dart';
import 'package:selfhelper/model/db.dart';
import 'package:selfhelper/model/models.dart' as model;


/// Singleton managing the notifications.
///
/// At the moment, only android is supported. For iOS support, see
/// https://github.com/MaikuB/flutter_local_notifications/tree/master/flutter_local_notifications
class NotificationsManager {
  static final NotificationsManager  _instance = NotificationsManager._internal();
  static final _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final _notificationOSSpecificDetails = NotificationDetails(
      AndroidNotificationDetails('be better notifications',
          'Reminders', 'These are the reminders shown to you for the chapters already'
              'read. You can change the frequency and the time of showing in the'
              'account settings.',
      styleInformation: BigTextStyleInformation('')),
      IOSNotificationDetails()
  );

  NotificationsManager._internal() {
    var settingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    var settingsIOS = IOSInitializationSettings();
    var settings = InitializationSettings(settingsAndroid, settingsIOS);
    _notificationsPlugin.initialize(settings,
      onSelectNotification: (String payload) async {
        if (payload == null) return;
        Payload payloadObj = Payload.fromString(payload);
        model.Path chosenPath = await DatabaseService().getChosenPath();
        await MyApp.navigatorKey.currentState.push(
          OnlyFadeRoute(
            builder: (_) => ChapterScreen(
              chosenPath.chapters[payloadObj.chapterIndex],
              payloadObj.chapterIndex,
              hasBeenRead: true,
            ),
          ),
        );
      }
    );
  }

  factory NotificationsManager() {
    return _instance;
  }

  Future<NotificationAppLaunchDetails> get launchDetails async {
    return _notificationsPlugin.getNotificationAppLaunchDetails();
  }

  /// returns map containing a random notification, its chapter index and
  /// notification index.
  ///
  /// Picks a random chapter from [chaptersRead] and then a random notification
  /// from this chapter. The response map has the form of
  /// {
  ///   'notification' : Notification,
  //    'chapterIndex' : int,
  //    'notificationIndex': int,
  /// }
  static Map<String, dynamic> pickRandomReminder(Iterable<model.Chapter> chaptersRead) {
    final int randChapter = Random().nextInt(chaptersRead.length);
    final int notificationsLength = chaptersRead.elementAt(randChapter).notifications.length;
    final int randNotification = Random().nextInt(notificationsLength);
    return {
      'notification' : chaptersRead.elementAt(randChapter).notifications[randNotification],
      'chapterIndex' : randChapter,
      'notificationIndex': randNotification,
    };
  }

  static Iterable<model.Chapter> listOfChaptersRead(model.Path path, List<int> chaptersRead) {
    return chaptersRead.map((i) => path.chapters[i]);
  }

  /// returns a shuffled list of the [ReminderTime] times when the user wants to
  /// receive a reminder.
  ///
  /// The boolean morning-, noon- and evening-reminder in the shared preference
  /// must be set.
  /// An example list could look like
  /// [ReminderTime.evening, ReminderTime.noon]
  static Future<List<ReminderTime>> reminderTimesAccordingUserPreferences() async {
    Iterable<bool> sends = await Future.wait([DatabaseService().morningReminder,
      DatabaseService().morningReminder, DatabaseService().morningReminder]);
    bool sendMorning = sends.elementAt(0);
    bool sendNoon = sends.elementAt(1);
    bool sendEvening = sends.elementAt(2);

    List<ReminderTime> reminderTimes = [];
    if (sendMorning) reminderTimes.add(ReminderTime.morning);
    if (sendNoon) reminderTimes.add(ReminderTime.noon);
    if (sendEvening) reminderTimes.add(ReminderTime.evening);
    reminderTimes.shuffle();
    int numReminders = min(await DatabaseService().numRemindersPerDay, reminderTimes.length);
    reminderTimes.removeRange(numReminders, reminderTimes.length);
    return(reminderTimes);
  }

  static _scheduleNotifications(model.Path path, List<int> chaptersReadIndices) async {
    // if pending notifications -> cancel all
    await _notificationsPlugin.cancelAll();
    // schedule new notifications
    DateTime now = DateTime.now();
    List<ReminderTime> reminderTimes = await reminderTimesAccordingUserPreferences();
    Iterable<model.Chapter> chaptersRead = listOfChaptersRead(path, chaptersReadIndices);


    for (int dayOffset = 0; dayOffset < 10; dayOffset++) {
      DateTime futureDay = now.add(Duration(days: dayOffset));

      for (int i = 0; i < reminderTimes.length; i++) {
        ReminderTime reminderTime = reminderTimes[i];
        Map response = pickRandomReminder(chaptersRead);
        model.Notification notif = response['notification'];
        TimeOfDay timeOfReminder = await ReminderTimeMapper.getExactTimeOfReminder(reminderTime);
        // skip notifications from earlier of today
        if (dayOffset == 0 && firstIsEarlier(timeOfReminder, TimeOfDay.fromDateTime(now)))
          continue;
        await _notificationsPlugin.schedule(dayOffset * 10 + i, notif.title, notif.body,
            DateTime(futureDay.year, futureDay.month, futureDay.day,
                timeOfReminder.hour, timeOfReminder.minute)
            , _notificationOSSpecificDetails,
            payload: Payload.createPayload(response['chapterIndex'])
        );
      }
    }
  }


  /// schedules reminders for the next 14 days.
  ///
  /// [path] is the chosen path of the user. If no [path] was selected, i.e.
  /// [path] == null, this function does nothing.
  ///
  /// [chaptersReadIndices] is the list of the indices which were already read
  ///
  /// Scheduling ahead vs. periodic cron jobs: Apparently it's not that easy
  /// to do background tasks in iOS. Also, as we already know all reminders,
  /// it would unnecessarily drain the user's battery if the app has to be
  /// run at most three times a day. That why I decided for scheduling ahead
  /// for now. This has one big caveat: We have to plan ahead for a fixed amount
  /// of days, so this function should be run ideally on every app start to
  /// avoid that the user won't get reminders at some point in the future.
  ///
  /// Threading vs async: I tried my best to run the scheduling code on another
  /// thread as an isolate. Unfortunately there were errors with th plugin, even
  /// when using isolate_helper which supposedly allows plugins to work with
  /// isolates. For now I will have to live with async.
  scheduleNotifications(model.Path path, {List<int> chaptersReadIndices}) async {
    if (path == null) return;
    if (chaptersReadIndices == null) {
      chaptersReadIndices = await DatabaseService()
          .getReadChapters(path.uid, path.id);
      if (chaptersReadIndices == null || chaptersReadIndices.isEmpty) {
        return;
      }
    }
    try {
       await Future.delayed(Duration(milliseconds: 200), () => _scheduleNotifications(path, chaptersReadIndices));
    } catch (err) {
      throw err;
    }
  }

  static bool firstIsEarlier(TimeOfDay first, TimeOfDay second) {
    if (first.hour < second.hour) return true;
    if (first.hour == second.hour && first.minute < second.minute) return true;
    return false;
  }

  sendTestNotification() async {
    var scheduledNotificationDateTime = DateTime.now().add(Duration(seconds: 10));
    await _notificationsPlugin.schedule(
        9999,
        'scheduled title',
        'scheduled body',
        scheduledNotificationDateTime,
        _notificationOSSpecificDetails,
    payload: Payload.createPayload(3));
  }
}

class Payload {
  final int chapterIndex;

  Payload._internal(this.chapterIndex);

  factory Payload.fromString(String payload) {
    var obj = jsonDecode(payload);
    if (obj['chapter'] == null || !(obj['chapter'] is int)) throw Error();
    return Payload._internal(obj['chapter']);
  }

  static String createPayload(int chapterNr) {
    return jsonEncode({
      'chapter' : chapterNr
    });
  }
}


class ReminderTimeMapper {
  static Future<TimeOfDay> getExactTimeOfReminder(ReminderTime rt) async {
    List<TimeOfDay> times = await DatabaseService().timesReminder;
    if (rt == ReminderTime.morning) return times[0];
    if (rt == ReminderTime.noon) return times[1];
    if (rt == ReminderTime.evening) return times[2];
    throw Error();
  }
}

enum ReminderTime {
  morning,
  noon,
  evening,
}
