module greeter;

import std.stdio;
import std.string;

class Greeter {
 private string greeting;

 public:
  this(in string greeting) {
    this.greeting = greeting.dup;
  }

  string makeGreeting(in immutable string thing) {
    return format("%s %s!", this.greeting, thing);
  }

  void greet(in immutable string thing) {
    writeln(makeGreeting(thing));
  }
}

unittest {
  auto greeter = new Greeter("Hello");
  assert(greeter.makeGreeting("world") == "Hello world!");
}
