import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/int
import gleam/io
import gleam/string

pub fn main() {
  // A "process" in gleam is a lightweight, concurrent unit of execution.
  // Other languages might call this a "coroutine" or a "green thread".
  // Every process has a unique identifier called a "process id" or "pid"
  // for short. These can be used to monitor or kill processes.
  let pid = process.self()
  io.println("Current process id: " <> string.inspect(pid))

  // We can spawn a new process using the `start` function. It takes two
  // arguments: a function to run in the new process, and a boolean indicating 
  // whether the new process should be "linked" to the current process.
  // "Linked" processes fail together (one crashing causes the other to crash).
  // The link is bidirectional.
  process.start(
    fn() {
      let pid = process.self()
      io.println("New process id: " <> string.inspect(pid))
    },
    True,
  )

  // Doing work in other processes is well and good, but if we want to
  // send messages between different processes, we need a `Subject`.
  // The subject is a combination of a unique identifier and the process id
  // of the process that created it.
  // (Note: If you're coming from Erlang/Elixir, a subject is like `from()` https://www.erlang.org/doc/man/gen_server#type-from)
  let subj = process.new_subject()

  // Once we have a subject, we can use it to send messages to the owner
  // process from any other process.
  process.start(fn() { process.send(subj, "hello, world") }, True)

  // The `receive` function is used to listen for messages sent to the subject.
  let assert Ok("hello, world") = process.receive(subj, 1000)

  // Note: If you've ever dabbled in Erlang/Elixir concurrency tutorials, you may be used
  // to sending messages to a pid directly. In Gleam, we use subjects, which 
  // have a few advantadges over process ids:
  // - They are generic over the message type, so we get type safe messages.
  // - You can have multiple per process. You can use multiple subjects to
  //   decouple the order in which messages are sent from the order in which they
  //   are received.

  // Lets make a second subject.
  let subj2 = process.new_subject()

  // Here we spawn a new process, and use the subjects to send messages
  // back to our current process.
  process.start(
    fn() {
      process.send(subj, "goodbye, mars")
      process.send(subj2, "whats up, pluto")
    },
    True,
  )

  // We can use each subject to receive the specific message we care about,
  // and we don't have to worry about the order in which the messages are sent.
  let assert Ok("whats up, pluto") = process.receive(subj2, 1000)
  let assert Ok("goodbye, mars") = process.receive(subj, 1000)

  // Typically, when writing concurrent programs in Gleam, you won't work 
  // with individual processes a lot. Instead, you'll use higher-level
  // constructs.
  //
  // If you want something like a server, a long running process which will
  // receive and respond to messages, the "actor" abstraction is the way to
  // go. (An "actor" is Gleam's equivalent of Erlang/Elixir's `gen_server`.
  // It has a different name because it has a different API due to static typing,
  // but it's the same concept.)
  //
  // If you want to run a bunch of processes concurrently to perform
  // work and collect their results OR you want to convert portions of
  // synchronous code to run concurrently and only block once you need
  // the results, you'll want the `Task` module. It's great for the dead simple
  // "do this somewhere else and I'll let you know when I need it" case.
  //
  // Before you run off reading those sections though, lets discuss subjects a 
  // bit more.

  let subject: Subject(String) = process.new_subject()

  // A subject works a bit like a mailbox. You can send messages
  // to it from any process. You can only receive messages
  // from it in the process that created it. 
  // Under the hood, every erlang process has it's own mailbox.
  // Subjects help us organize that mailbox, but you can't swap 
  // mailboxes with your neighbor.

  process.start(
    fn() { process.send(subject, "hello from some rando process") },
    True,
  )

  let assert Ok("hello from some rando process") =
    process.receive(subject, 1000)

  // Notice that the subjects type is `Subject(String)`. Subjects are generic
  // over the type of message they can send/receive.
  // This is nice because the type system will help us ensure that we're not sending/receiving
  // the wrong type of message, and we can do less runtime checking than in a dynamic language.

  // The other thing you'll want to know about is "selectors". Remember the example from earlier,
  // where we sent messages from two different subjects? We had to choose which ones to wait for
  // first (we waited for pluto, then dealt with mars after).
  // What if we wanted to deal with messages as they came in, regardless of which subject they came from?
  // That's what selectors are for. They let you wait for messages from multiple subjects at once.

  // The catch is that selecting from a selector has to produce only one type of message, so you'll
  // need to map the messages to a common type.
  // In this example, I want to receive messages as strings, so I tell the selector to turn subject 1's
  // messages into a string using `int.to_string`, and to leave subject 2's messages alone 
  // using `function.identity`.

  // Try sending the messages in different order to see the selector in action!

  let subject1: Subject(Int) = process.new_subject()
  let subject2: Subject(String) = process.new_subject()
  let selector =
    process.new_selector()
    |> process.selecting(subject1, int.to_string)
    |> process.selecting(subject2, function.identity)

  process.start(fn() { process.send(subject1, 1) }, True)
  process.start(fn() { process.send(subject2, "2") }, True)

  let assert Ok(some_str) = process.select(selector, 1000)
  io.println("Received: " <> some_str)
  let assert Ok(some_str_2) = process.select(selector, 1000)
  io.println("Received: " <> some_str_2)

  // Hopefully this introduction made sense. If you're reading in the recommended order,
  // head over to tasks.gleam next.
}
