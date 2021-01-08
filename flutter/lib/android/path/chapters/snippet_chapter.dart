import 'package:flutter/material.dart';
import 'package:selfhelper/android/onlyfadepagerouter.dart';
import 'package:selfhelper/android/path/chapters/chapter_expanded_screen.dart';
import 'package:selfhelper/model/models.dart' as model;

/// the inner widgets of the chapter
class ChapterInner extends StatelessWidget {
  final bool hasBeenRead;
  final model.Chapter chapter;

  ChapterInner(this.hasBeenRead, this.chapter);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: hasBeenRead ? Colors.green : Theme.of(context).colorScheme.error,
                  width: 8))),
      child: Padding(
        // inner padding
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            Expanded(
              child: RichText(
                maxLines: 11,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                    style: Theme.of(context).textTheme.bodyText2,
                    children: [
                      TextSpan(
                          text: chapter.title + '\n\n',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                        text: chapter.content,
                      )
                    ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 24,
                  )),
            )
          ],
        ),
      ),
    );;
  }
}


/// container for fully visible chapter snippet, ie no white fading overlay
class FullyVisibleChapterContainer extends StatelessWidget {
  final model.Chapter chapter;
  final int chapterNr;
  final void Function(int) onRead;
  final bool hasBeenRead;

  /// displays a [chapter] snippet.  If chapter is clicked, it opens
  /// the corresponding [ChapterScreen] which takes the remaining parameters.
  FullyVisibleChapterContainer(this.chapter, this.chapterNr,
      {this.onRead, this.hasBeenRead: false});

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.7;
    return SizedBox(
        width: cardWidth,
        child: InkWell(
            onTap: () => Navigator.push(
                context,
                OnlyFadeRoute(
                    builder: (_) => ChapterScreen(chapter, chapterNr,
                        onRead: this.onRead, hasBeenRead: this.hasBeenRead))),
            child: Hero(
                tag: chapterNr,
                child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ChapterInner(hasBeenRead, chapter)))));
  }
}

/// container for chapter snippet with a white overlay, indicating the last one
class FadedOutChapterContainer extends StatelessWidget {
  final model.Chapter chapter;
  final bool hasBeenRead;

  /// displays a [chapter] snippet.  If chapter is clicked, it opens
  /// the corresponding [ChapterScreen] which takes the remaining parameters.
  FadedOutChapterContainer(this.chapter, {this.hasBeenRead: false});

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.7;
    return SizedBox(
      width: cardWidth,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            ChapterInner(hasBeenRead, chapter),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        stops: [0.0, 0.8],
                        colors: [Colors.white.withOpacity(0.3), Colors.white])),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// displays a snippet of a chapter
class ChapterSnippet extends StatelessWidget {
  final model.Chapter chapter;
  final int chapterNr;

  /// fade set to true puts a white linear gradient over the last snippet and
  /// makes it non-clickable.
  final bool fade;

  /// these are used to mark chapter as read
  final void Function(int) onRead;
  final bool hasBeenRead;

  ChapterSnippet(this.chapter, this.chapterNr,
      {this.fade: false, this.onRead, this.hasBeenRead: false});

  @override
  Widget build(BuildContext context) {
    return (!fade)
        ? FullyVisibleChapterContainer(chapter, chapterNr, onRead: onRead, hasBeenRead: hasBeenRead,)
        : FadedOutChapterContainer(chapter, hasBeenRead: hasBeenRead);
  }
}