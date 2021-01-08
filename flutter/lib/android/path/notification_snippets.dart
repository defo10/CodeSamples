import 'package:flutter/material.dart';
import 'package:selfhelper/android/texts.dart';
import 'package:selfhelper/model/models.dart' as model;

/// The container, i.e. padding and card of a notification snippet
class NotificationContainer extends StatelessWidget {
  final Widget child;

  NotificationContainer({this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: SizedBox(
        width: double.maxFinite, // 100 % width
        child: Card(elevation: 1, child: this.child),
      ),
    );
  }
}

/// A the content of one notification snippet (i.e. without surrounding card)
class NotificationSnippetContent extends StatelessWidget {
  final model.Notification notification;

  NotificationSnippetContent(this.notification);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: RichText(
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(style: Theme.of(context).textTheme.bodyText2, children: [
          TextSpan(
              text: notification.title + '\n',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text: notification.body,
          )
        ]),
      ),
    );
  }
}

/// The content of notification snippet with a fading effect from the bottom
/// overlaying it
class FadedOutNotificationContent extends StatelessWidget {
  final model.Notification notification;

  FadedOutNotificationContent(this.notification);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      NotificationSnippetContent(notification),
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.8],
                  colors: [Colors.white.withOpacity(0), Colors.white])),
        ),
      )
    ]);
  }
}

/// the Reminders section of a path preview.
///
/// Shows a subset of the notifications to show.
class Reminders extends StatelessWidget {
  // selection of notifications to show
  final List<model.Notification> notifs = [];

  /// picks 3 notifications [fromChapters] at random and put to [allNotifications].
  pickRandomNotifications(List<model.Chapter> fromChapters) {
    List<model.Notification> allNotifications = [
      for (var chapter in fromChapters)
        for (var notification in chapter.notifications) notification
    ];

    if (allNotifications.length <= 5) {
      this.notifs.addAll(allNotifications);
      return;
    }

    allNotifications
      ..shuffle()
      ..removeRange(4, allNotifications.length);

    this.notifs.addAll(allNotifications);
  }

  Reminders(List<model.Chapter> chapters) : assert(chapters != null) {
    pickRandomNotifications(chapters);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Headline('Reminders', 155),
        for (int i = 0; i < notifs.length; i++)
          (i == notifs.length - 1) // is last element?
              ? NotificationContainer(
                  child: FadedOutNotificationContent(notifs[i]))
              : NotificationContainer(
                  child: NotificationSnippetContent(notifs[i]),
                )
      ],
    );
  }
}
