import std.stdio;
import examples.d.hello_lib.greeter;

void main() {
  Greeter greeter = new Greeter("Hello");
  greeter.greet("World");
}
