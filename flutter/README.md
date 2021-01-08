# pocket wisdom (wip)

this is smaller excerpt of my code for an app I'm developing on the side. Generally speaking, the goal is to give users summaries / reminders of books. There's a react front-end in development which allows anyone to enter new paths.

## Some terminology for better understanding the code:

### path
is like a book a user subscribes to. A path consists of chapters. Each chapter has most notably a corresponding chapter text and reminders (which are nothing but notifications).

# what to look at

It's all more or less the same. I would advise to have a look at lib/android/path/path_screen.dart . The widget PathScreen is the main widget for displaying paths. I think there's a cool animation when the user wants to see more informations about the creator of the path. On a button click, the the button animates and reveals the creator's other paths. This is done in lib/android/path/path_creator.dart

Otherwise, the structure is rather straightforward:

android contains all android-specific code, with each subfolder (account, discover, ...) for a separate screen. path is used in multiple screens as it is one of the core widgets.
