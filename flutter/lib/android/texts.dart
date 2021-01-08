/// Contains all custom text-related widgets.

import 'package:flutter/material.dart';

/// A headline with a slightly shifted yellow underline.
class Headline extends StatelessWidget {
  final String text;
  final double textLengthPxs;

  /// Displays a headline of [text] and a yellow offset block with width [textLengthPxs].
  ///
  /// We have to estimate the text length in pixels, [textLengthPxs], ourselves.
  /// Unfortunately, there are no good ways to estimate the pixel width of a
  /// string, as different chars have different pixel widths.
  const Headline(this.text, this.textLengthPxs);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 32),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Stack(
          overflow: Overflow.visible,
          children: <Widget>[
            Positioned(
              top: 25,
              left: 10,
              child: Container(
                width: textLengthPxs,
                height: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            Text(text, style: Theme.of(context).textTheme.headline5),
          ],
        ),
      ),
    );
  }
}
