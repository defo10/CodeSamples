# pocket wisdom (wip)

this is smaller excerpt of my code for an app I'm developing on the side. Generally speaking, the goal is to give users summaries / reminders of books. There's a react front-end in development which allows anyone to enter new paths.

## Some terminology for better understanding the code:

### path
is like a book a user subscribes to. A path consists of chapters. Each chapter has most notably a corresponding chapter text and reminders (which are nothing but notifications).

# what to look at

It's all more or less the same. I would advise to have a look at [lib/android/path/path_screen.dart](lib/android/path/path_screen.dart) . The widget PathScreen is the main widget for displaying paths. 
I think there's a cool animation when the user wants to see more informations about the creator of the path. On a button click, the button animates and reveals the creator's other paths. This is done in [lib/android/path/path_creator.dart](lib/android/path/path_creator.dart)

Otherwise, the structure is rather straightforward:

android contains all android-specific code, with each subfolder (account, discover, ...) for a separate screen. path is used in multiple screens as it is one of the core widgets.

# media

you can watch a very small walkthrough of the files I uploaded here: https://drive.google.com/file/d/1SRdO4Irmni0_SVzYf8fMvFTTlmHJn-QT/view?usp=sharing

pics:

![1](https://github.com/defo10/CodeSamples/blob/main/flutter/1.png)

![2](https://github.com/defo10/CodeSamples/blob/main/flutter/2.png)

![3](https://github.com/defo10/CodeSamples/blob/main/flutter/3.png)

![4](https://github.com/defo10/CodeSamples/blob/main/flutter/4.png)
