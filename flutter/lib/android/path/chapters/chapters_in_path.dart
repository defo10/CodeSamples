import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:selfhelper/android/path/chapters/snippet_chapter.dart';
import 'package:selfhelper/android/path/path_screen.dart';
import 'package:selfhelper/android/texts.dart';
import 'package:selfhelper/model/models.dart' as model;
import 'package:selfhelper/vm/chapter_interaction_vm.dart';


/// the chapters in the preview mode.
///
/// In this mode, we don't keep track of the read chapters.
class PreviewChapters extends StatelessWidget {
  final model.Path path;

  PreviewChapters(this.path);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Headline('Chapters', 130),
        SizedBox(
          height: 300,
          child: ListView.builder(
            physics: BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: path.chapters.length,
            itemBuilder: (_, index) {
              bool isLastItem = index == path.chapters.length - 1;
              if (isLastItem)
                return (Padding(
                  padding: EdgeInsets.all(8),
                  child: ChapterSnippet(path.chapters[index], index,
                      fade: true),
                ));
              return (Padding(
                padding: EdgeInsets.all(8),
                child: ChapterSnippet(path.chapters[index], index),
              ));
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 64),
        )
      ],
    );
  }
}

/// Builds the chapters of the chosen path, after reading them from
/// [ChaptersVM].
class InnerChapterOfChosenPath extends StatelessWidget {
  final model.Path path;

  InnerChapterOfChosenPath(this.path);

  @override
  Widget build(BuildContext context) {
    ChaptersVM chapters = Provider.of<ChaptersVM>(context);

    return FutureBuilder(
        future: chapters.chaptersRead,
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Headline('Chapters', 130),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: path.chapters.length,
                  itemBuilder: (_, index) {
                    // performance could be improved by only going through
                    // list below once (the list is ordered). So now its
                    // O(nrChapters * lengthChaptersRead) instead of
                    // O(nrChapters + lengthChaptersRead) possibly
                    // but its so much easier this way so KISS
                    bool hasBeenRead = snapshot.data.contains(index);
                    return (Padding(
                      padding: EdgeInsets.all(8),
                      child: ChapterSnippet(
                        path.chapters[index],
                        index,
                        onRead: chapters.updateChaptersRead,
                        hasBeenRead: hasBeenRead,
                      ),
                    ));
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 64),
              )
            ],
          );
        });
  }
}


/// chapters when clicked from the chosen path.
///
/// keeps track of the read chapters.
class ChaptersOfChosenPath extends StatelessWidget {
  final model.Path path;
  final String docid;

  ChaptersOfChosenPath(this.path, this.docid);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      lazy: false,
      create: (_) => ChaptersVM(path, docid),
      child: InnerChapterOfChosenPath(path),
    );
  }
}


/// section of chapters within a [PathScreen].
///
class PathChapters extends StatelessWidget {
  final model.Path path;
  final String uid;
  final String docid;
  final bool isChosenOne;

  PathChapters(this.path, this.uid, this.docid, {this.isChosenOne = false});

  @override
  Widget build(BuildContext context) {
    return isChosenOne
      ? ChaptersOfChosenPath(path, docid)
    : PreviewChapters(path);
  }
}