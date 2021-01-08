import 'package:flutter/material.dart';
import 'package:selfhelper/android/path/chapters/chapters_in_path.dart';
import 'package:selfhelper/android/path/notification_snippets.dart';
import 'package:selfhelper/android/path/path_choosing.dart';
import 'package:selfhelper/android/path/path_creator.dart';
import 'package:selfhelper/android/texts.dart';
import 'package:selfhelper/model/models.dart' as model;

/// The title of the path on the path screen.
class PathTitle extends StatelessWidget {
  /// Note to myself: Sadly, I can't use [Headline] for this title as of now.
  /// This is due to not being able to accurately estimate the title width,
  /// which is needed for [Headline].
  final String title;

  PathTitle(this.title) : assert(title != null);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 42, 32, 42),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headline4,
      ),
    );
  }
}

/// The introduction text on the path screen
class PathIntro extends StatelessWidget {
  final String intro;

  PathIntro(this.intro);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.fromLTRB(32, 0, 32, 42), child: Text(intro));
  }
}

/// Displays the background image of a path
class BackgroundImage extends StatelessWidget {
  final bool isChosenOne;
  final String imageUrl;
  final String id;

  /// See [model.Path] for descriptions of parameters.
  BackgroundImage(this.isChosenOne, this.imageUrl, this.id);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: isChosenOne
            ? Image(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
            : Hero(
                // nice animation for when new path was clicked on, e.g. in [NewestPaths]
                tag: 'coverimage-' + id,
                child: Image(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
      )
    ]);
  }
}

/// The sliver app bar for the path screen.
///
/// This is the app bar which first shows an image and, as soon as the user
/// scrolls, folds into a material app bar
class PathSliverAppBar extends StatelessWidget {
  final bool isChosenOne;
  final model.Path path;

  PathSliverAppBar(this.isChosenOne, this.path);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
        floating: false,
        pinned: true,
        snap: false,
        expandedHeight: 300,
        forceElevated: true,
        stretch: true,
        elevation: 4,
        backgroundColor: Theme.of(context).colorScheme.primary,
        brightness: Brightness.dark,
        leading: isChosenOne
            ? null // don't show back arrow on main path
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: Colors.white),
              ),
        flexibleSpace: FlexibleSpaceBar(
          stretchModes: [
            StretchMode.zoomBackground,
            StretchMode.fadeTitle,
          ],
          background: BackgroundImage(isChosenOne, path.imageUrl, path.id),
        ));
  }
}

/// screen for a path.
///
/// [isChosenOne] indicates that the user has chosen this path, so the
/// underlying path is not the preview version but the full one. This makes
/// all notifications and chapters visible, without fading the last respective
/// one out.
class PathScreen extends StatelessWidget {
  final model.Path path;
  final bool isChosenOne;

  PathScreen(this.path, {this.isChosenOne = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          PathSliverAppBar(isChosenOne, path),
          SliverList(
              delegate: SliverChildListDelegate([
            PathTitle(path.title),
            PathCreatorSection(path.user, path.uid, path.id),
            PathIntro(path.intro),
            PathChapters(path, path.uid, path.id,
                isChosenOne: this.isChosenOne),
            isChosenOne ? Container() : Reminders(path.chapters),
            isChosenOne ? Container() : PathChoosingBtn(path),
          ]))
        ],
      ),
    );
  }
}
