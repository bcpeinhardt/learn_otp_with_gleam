//// An implementation of a "pantry" using an actor.
//// 
//// 

import gleam/otp/actor
import gleam/erlang/process.{type Subject}
import gleam/set.{type Set}

// Below this comment are the public functions that we want to expose to other modules.
// Some things to note:
// - The functions all take a `Subject(Message)` as their first argument. 
//   We use this to send messages to the actor. We could abstract that away further, 
//   so the user doesn't have to manage the subject themselves, but following this
//   pattern will help us integrate with something called a `supervisor` later on, and it
//   matches how working with normal data in Gleam usually works too `operation(subject, arg1, arg2...)`.
// - Functions that need to get a message back from the actor use `actor.call` to send a message
//   and wait for a reply. This is a synchronous operation, and it will block the calling process.
// - Functions that don't need a reply use `actor.send` to send a message to the actor. These are asynchronous.
//   No checking is done to see if the message was received or not, it's fire and forget.

const timeout: Int = 5000

/// Create a new pantry actor.
pub fn new() -> Result(Subject(Message), actor.StartError) {
  actor.start(set.new(), handle_message)
}

/// Add an item to the pantry.
pub fn add_item(pantry: Subject(Message), item: String) -> Nil {
  actor.send(pantry, AddItem(item))
}

/// Take an item from the pantry.
pub fn take_item(pantry: Subject(Message), item: String) -> Result(String, Nil) {
  // See that `_`? That's a placeholder for the reply subject. It will be injected for us by `call`.
  //
  // If the underscore syntax is confusing, it's called a [function capture](https://tour.gleam.run/functions/function-captures/).
  // It's a shorthand for `fn(reply_with) { TakeItem(reply_with, item) }`.
  //
  // Also, since we need to wait for a response, we pass a timeout as the last argument so we don't get stuck
  // waiting forever if our actor gets struck by lightning or something.
  actor.call(pantry, TakeItem(_, item), timeout)
}

/// Close the pantry.
pub fn close(pantry: Subject(Message)) -> Nil {
  actor.send(pantry, Shutdown)
}

// That's our entire public API! Now let's look at the actor that runs it.

/// The messages that the pantry actor can receive.
pub type Message {
  AddItem(item: String)
  // Take item takes a reply subject. Any message that needs to send a reply back
  // should take a subject argument for the handler to reply back with.
  // Subjects are generic over their message type, and `Result(String, Nil)` is the type
  // we want our public `take_item` function to return.
  // Really compare this message with the `take_item` function above, and make sure the 
  // relationship makes sense to you.
  TakeItem(reply_with: Subject(Result(String, Nil)), item: String)
  Shutdown
}

// This is our actor's message handler. It's a function that takes a message and the current state of the actor,
// and returns a new state and a new state for the actor to continue with.
//
// There's nothing really magic going on under the hood here. An actor is really just a recursive function that
// holds state in its arguments, receives a message, possibly does some work or send messages back to other processes, 
// and then calls itself with some new state. The `actor.Next` type is just an abstraction over that pattern.
//
// In fact, take a look at [it's definition](https://hexdocs.pm/gleam_otp/gleam/otp/actor.html#Next) 
// and you'll see what I mean (don't worry about selectors yet).
fn handle_message(
  message: Message,
  pantry: Set(String),
) -> actor.Next(Message, Set(String)) {
  // We pattern match on the message to decide what to do.
  case message {
    // This type of message will be in most actors, it's worth just sticking 
    // at the top.
    Shutdown -> actor.Stop(process.Normal)

    // We're adding an item to the pantry. We don't need to reply to anyone, so we just
    // send the new state back to the actor to continue with.
    AddItem(item) -> actor.continue(set.insert(pantry, item))

    // We're taking an item from the pantry. The `TakeItem` message has a client subject
    // for us to send our reply with.
    TakeItem(client, item) ->
      case set.contains(pantry, item) {
        // If the item isn't in the pantry set,
        // send back an error to the client and continue with the current state.
        False -> {
          process.send(client, Error(Nil))
          actor.continue(pantry)
        }

        // If the item is in the pantry set, send it back to the client,
        // and continue with the item removed from the pantry.
        True -> {
          process.send(client, Ok(item))
          actor.continue(set.delete(pantry, item))
        }
      }
  }
}
