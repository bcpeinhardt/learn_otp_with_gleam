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
}
