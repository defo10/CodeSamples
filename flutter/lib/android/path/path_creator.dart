/// All widgets which are needed for showing more informations about a path's
/// creator.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:selfhelper/android/path/snippet_path.dart';
import 'package:selfhelper/vm/creator_paths_viewmodel.dart';

/// Creator-section of  the path
///
/// contains an animation controller to allow a button, [PathCreatorButton],
/// to reveal [ExpandedCreatorInfo], and has a [ChangeNotifier] linked
/// to the current path's creator
class PathCreatorSection extends StatefulWidget {
  final String creatorName;
  final String uid;
  final String docid;

  PathCreatorSection(this.creatorName, this.uid, this.docid)
      : assert(creatorName != null),
        assert(uid != null);

  @override
  _PathCreatorSectionState createState() => _PathCreatorSectionState();
}

class _PathCreatorSectionState extends State<PathCreatorSection>
    with SingleTickerProviderStateMixin {
  AnimationController _creatorInfocontroller;

  @override
  void initState() {
    super.initState();
    _creatorInfocontroller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
  }

  hideCreatorInfo() => setState(() {
        _creatorInfocontroller.forward();
      });

  revealCreatorInfo() => setState(() {
        _creatorInfocontroller.reverse();
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PathCreatorButton(
            revealCreatorInfo, hideCreatorInfo, widget.creatorName),
        SizeTransition(
          axisAlignment: -1.0,
          sizeFactor: CurvedAnimation(
            parent: _creatorInfocontroller,
            curve: Curves.easeIn,
          ),
          child: ChangeNotifierProvider<CreatorPathVM>.value(
            value: CreatorPathVM(3, widget.uid, filterDocId: widget.docid),
            child: ExpandedCreatorInfo(widget.creatorName),
          ),
        ),
      ],
    );
  }
}

/// Button showing the path's author and an arrow which rotates on click,
/// calling listeners in [PathCreatorSection] to reveal [ExpandedCreatorInfo]
class PathCreatorButton extends StatefulWidget {
  final void Function() reveal;
  final void Function() hide;
  final String creatorName;

  PathCreatorButton(this.reveal, this.hide, this.creatorName);

  @override
  _PathCreatorButtonState createState() => _PathCreatorButtonState();
}

class _PathCreatorButtonState extends State<PathCreatorButton>
    with SingleTickerProviderStateMixin {
  AnimationController _btnController;

  @override
  void initState() {
    super.initState();
    _btnController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: pi,
    );
  }

  @override
  void dispose() {
    _btnController.dispose();
    super.dispose();
  }

  bool _isExpandedOrExpanding() =>
      (_btnController.status == AnimationStatus.completed ||
          _btnController.status == AnimationStatus.forward);

  void expandInfo(AnimationController btnController) {
    btnController.reverse(); // rotates arrow
    widget.reveal(); // reveals [ExpandedCreatorInfo]
  }

  void closeInfo(AnimationController btnController) {
    btnController.forward(); // rotates arrow
    widget.hide(); // hides [ExpandedCreatorInfo]
  }

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Align(
        alignment: Alignment.centerRight,
        child: OutlineButton(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          onPressed: () {
            setState(() {
              _isExpandedOrExpanding()
                  ? expandInfo(_btnController)
                  : closeInfo(_btnController);
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnimatedBuilder(
                animation: _btnController,
                builder: (context, child) => Transform.rotate(
                  angle: _btnController.value,
                  child: child,
                ),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              Text(
                widget.creatorName,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// widget showing the other snippets of a creator.
///
/// This is revealed by [PathCreatorSection]
class ExpandedCreatorInfo extends StatelessWidget {
  final String creatorName;

  ExpandedCreatorInfo(this.creatorName);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryVariant,
          boxShadow: [
            const BoxShadow(
              spreadRadius: -8.0,
              blurRadius: 8.0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Other Paths from ' + creatorName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondary)),
            ),
            ListCreatorsOtherPaths(),
          ],
        ),
      ),
    );
  }
}

/// a horizontal list of snippets from the current path's creator
class ListCreatorsOtherPaths extends StatelessWidget {
  /// returns snippet of creators path at [index] and loads more
  /// if user nears end of list [pathsCreator]
  Snippet buildAndFetch(int index, CreatorPathVM pathsCreator) {
    if (!pathsCreator.hasMoreToCome) {
      return Snippet(
        pathsCreator.pathsOfCreator[index],
        compact: true,
      );
    }
    // if second to last snippet is rendered, load more
    if (pathsCreator.pathsOfCreator.length >= 2 &&
        index == pathsCreator.pathsOfCreator.length - 2)
      pathsCreator.loadMore();

    return Snippet(
      pathsCreator.pathsOfCreator[index],
      compact: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    CreatorPathVM creatorPath = Provider.of<CreatorPathVM>(context);

    return SizedBox(
      height: 200,
      child: ListView.builder(
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: creatorPath.pathsOfCreator.length,
          cacheExtent: 300, // Careful: this is a unit of storage, not indices
          itemBuilder: (context, index) => buildAndFetch(index, creatorPath)),
    );
  }
}
