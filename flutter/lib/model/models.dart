import 'package:cloud_firestore/cloud_firestore.dart';

class Path {
  final String id;
  final String uid;
  final String imageUrl;
  final String intro;
  final String language;
  final String price;
  final Timestamp publishedOn;
  final Timestamp timestamp;
  final String title;
  final List<Chapter> chapters;
  final String user;

  Path(this.id, this.uid, this.imageUrl, this.intro, this.language, this.price,
      this.publishedOn, this.timestamp, this.title, this.user, this.chapters);

  factory Path.fromMap(Map<String, dynamic> data) {
    return Path(
      data['id'],
      data['uid'],
      data['image'],
      data['intro'],
      data['language'],
      data['price'],
      data['publishedOn'],
      data['timestamp'],
      data['title'],
      data['user'],
      [for (var chapter in data['chapters']) Chapter.fromMap(chapter)],
    );
  }
}

class Chapter {
  final String title;
  final String content;
  final List<Notification> notifications;

  Chapter(this.title, this.content, this.notifications);

  factory Chapter.fromMap(Map data) {
    return Chapter(
        data['cTitle'],
        data['cContent'],
      [for (var notif in data['cNotifications']) Notification.fromMap(notif)],
    );
  }
}

class Notification {
  final String title;
  final String body;
  final TimePref timePref;

  Notification(this.title, this.body, this.timePref);

  factory Notification.fromMap(Map data) {
    return Notification(
      data['nTitle'],
      data['nBody'],
      TimePref(
        data['nTimePref']['bedtime'],
        data['nTimePref']['noon'],
        data['nTimePref']['morning'],
      ),
    );
  }
}

class TimePref {
  final bool bedtime;
  final bool noon;
  final bool morning;

  TimePref(this.bedtime, this.noon, this.morning);
}