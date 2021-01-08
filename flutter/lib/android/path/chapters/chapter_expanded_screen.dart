import 'package:flutter/material.dart';
import 'package:selfhelper/model/models.dart' as model;

/// displays the text of the corresponding [model.Chapter].
/// Enclosed in [ChapterScreen]
class _InnerCard extends StatelessWidget {
  final model.Chapter chapter;

  _InnerCard(this.chapter);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(16),
        child: RichText(
          text:
              TextSpan(style: Theme.of(context).textTheme.bodyText2, children: [
            TextSpan(
                text: chapter.title + '\n\n',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
              text: chapter.content,
            )
          ]),
        ));
  }
}

/// The card showing the chapter content shown in [ChapterScreen]
class _ContainerCard extends StatelessWidget {
  final model.Chapter chapter;
  final bool hasBeenRead;

  _ContainerCard(this.chapter, {this.hasBeenRead: false});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
        scrollDirection: Axis.vertical,
        child: Center(
          child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: hasBeenRead
                                ? Colors.green
                                : Theme.of(context).colorScheme.error,
                            width: 8))),
                child: _InnerCard(chapter),
              )),
        ),
      ),
    );
  }
}

/// This is the full screen view of on chapter.
///
/// It appears for example after clicking on a chapter snippet.
class ChapterScreen extends StatelessWidget {
  final model.Chapter chapter;
  final int chapterNr;

  /// this is used to mark a chapter as read
  final void Function(int) onRead;
  final bool hasBeenRead;

  /// displays [chapter] content. Calls [onRead] with [chapterNr] as argument
  /// on closing the chapter again.
  ChapterScreen(this.chapter, this.chapterNr,
      {this.onRead, this.hasBeenRead: false});

  Future<bool> _onWillPop() async {
    if (onRead != null) onRead(chapterNr);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // log closing of chapter and keep track of it
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          brightness: Brightness.dark,
          backgroundColor: Theme.of(context).colorScheme.primary,
          leading: IconButton(
            onPressed: () {
              if (onRead != null) onRead(chapterNr);
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back),
          ),
        ),
        body: Hero(
          tag: chapterNr,
          child: _ContainerCard(
            chapter,
            hasBeenRead: hasBeenRead,
          ),
        ),
      ),
    );
  }
}
