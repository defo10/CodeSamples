import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:selfhelper/android/onlyfadepagerouter.dart';
import 'package:selfhelper/android/path/path_screen.dart';
import 'package:selfhelper/model/models.dart' as model;

/// Displays the actual texts and icons in [Snippet]
class CardContent extends StatelessWidget {
  final model.Path path;
  final bool compact;

  CardContent(this.path, this.compact);

  @override
  Widget build(BuildContext context) {
    final _authorText = Padding(
      padding: EdgeInsets.only(bottom: (compact ? 2 : 4)),
      child: Text(
        path.user + "'s",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context)
            .textTheme
            .subtitle1
            .copyWith(fontStyle: FontStyle.italic),
      ),
    );

    final _titleText = Padding(
      padding: EdgeInsets.only(bottom: (compact ? 4 : 12)),
      child: Text(
        path.title,
        maxLines: compact ? 2 : 3,
        overflow: TextOverflow.ellipsis,
        style: compact
            ? Theme.of(context).textTheme.headline6.copyWith(fontSize: 16)
            : Theme.of(context).textTheme.headline6,
      ),
    );

    final _introText = Text(
      path.intro,
      overflow: TextOverflow.ellipsis,
      maxLines: compact ? 3 : 4,
      style: compact
          ? Theme.of(context).textTheme.subtitle1.copyWith(fontSize: 14)
          : Theme.of(context).textTheme.subtitle1,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _authorText,
            _titleText,
            _introText,
            Center(
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 24,
                color: Colors.white,
              ),
            )
          ]),
    );
  }
}

/// Defines the onClick behavior and animations for [Snippet]
class SnippetContent extends StatelessWidget {
  final model.Path path;
  final bool compact;

  /// Builds the content, ie the inside of [Snippet] widget of the given [path].
  SnippetContent(this.path, {this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Hero(
            tag: 'coverimage-${path.id}',
            child: Image(
              image: NetworkImage(path.imageUrl),
              fit: BoxFit.fill,
              alignment: Alignment.center,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),
        CardContent(path, compact),
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => Navigator.push(
                context, OnlyFadeRoute(builder: (_) => PathScreen(path))),
          ),
        )
      ],
    );
  }
}

/// Snippet of a given path
class Snippet extends StatelessWidget {
  final model.Path path;
  final bool compact;

  /// Builds a snippet widget of the given [path].
  ///
  /// [compact] indicates how much spacing should be around the snippet, and
  /// how many lines of text should be displayed
  Snippet(this.path, {this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: compact
          ? const EdgeInsets.only(left: 14, right: 14, bottom: 36)
          : const EdgeInsets.only(left: 38, right: 38, bottom: 32),
      child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Card(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              elevation: 12,
              child: SnippetContent(
                path,
                compact: compact,
              ))),
    );
  }
}
