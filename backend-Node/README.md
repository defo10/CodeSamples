# pocket wisdom (wip)

this is smaller excerpt of my code for an app I'm developing on the side. Generally speaking, the goal is to give users summaries / reminders of books. There's a react front-end in development which allows anyone to enter new paths.

## Some terminology for better understanding the code:

### path
is like a book a user subscribes to. A path consists of chapters. Each chapter has most notably a corresponding chapter text and reminders (which are nothing but notifications).

# what to look at

It's all in on file. The functions are longer than I like them, but I feel that it's reasonable for multiple simple validation checks.

For the tests I used mocha. Again, each test is rather long. This is because these are live tests, working on the real firebase database. So the program needs to delete and setup all the test resources. 

