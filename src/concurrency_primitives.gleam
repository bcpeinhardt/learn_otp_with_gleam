import gleam/io
import gleam/erlang/process
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

  // The `receive` function is used to listen for messages sent to the current process.
  let assert Ok("hello, world") = process.receive(subj, 1000)

  // Note: If you've ever dabbled in Erlang/Elixir concurrency tutorials, you may be used
  // to sending messages to a pid directly. In Gleam, we use subjects, which 
  // have a few advantadges over process ids:
  // - They are generic over the message type, so we get type safe messages.
  // - You can have multiple per process. You can use multiple subjects to
  //   decouple the order in which messages are sent from the order in which they
  //   are received.

  // Lets make a second subject, also owned by the current process.
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
  // receive and respond you messages, the "actor" abstraction is the way to
  // go. (An "actor" is Gleam's equivalent of Erlang/Elixir's `gen_server`.
  // It has a different name because it has a different API due to static typing,
  // but it's the same concept.)
  //
  // If you want to run a bunch of processes concurrently to perform
  // work and collect their results OR you want to convert portions of
  // synchronous code to run concurrently and only block once you need
  // the results, you'll want the `Task` module. It's great for the dead simple
  // "do this somewhere else and I'll let you know when I need it" case.

  // A WORD OF WARNING: OTP's abstractions are really powerful, and have been
  // tailored over decades so that they fit the mental model of a lot of
  // problems really well. It can be tempting to want to use them as organizational
  // constructs in the code base, especially coming from an OOP background, as processes can
  // hold and update state, but you should not do this.
  // Always ask yourself: Do I REALLY need concurrency here? REALLY REALLY?
  // If you find yourself reaching for processes/tasks/actors as a way to hold state,
  // rather than because you need concurrency for performance/scalability/fault tolerance reasons,
  // you are not the first and you won't be the last.

  // Below are some resources for learning functional design patterns to help reduce dependency
  // on stateful constructs:
  // Todo: find and vet said resources
}
