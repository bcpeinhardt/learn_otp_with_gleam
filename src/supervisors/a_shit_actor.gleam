//// This module implements a shit actor that crashes every now and then.
//// Having an actor that fails every now and then will help us test out our supervisors.
//// If you need a refresher on actors, go revisit the `actor.gleam` and `actor/pantry` code.
//// 
//// Alright, let's implement of game of Duck Duck Goose as an actor.
//// 
//// (If this game is unfamiliar to you, children sit in a circle while 
//// one of them walks around behind the rest tapping them and saying "duck"
//// or "goose". They say "duck" for awhile, and nothing happens, but when 
//// they choose the "goose" all hell breaks loose and they chase each other 
//// around the circle. Interestingly in the midwest of the United States the
//// game is often called "Duck, Duck, Grey Duck".)

import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/otp/actor
import prng/random

/// Okay, well this is new.
/// We're going to hand this actor off to supervisor,
/// which will manage starting it for us.
/// 
/// That means we can't simply get the subject out from 
/// the return, since we dont call the start function
/// directly. Instead, we'll have to send the subject
/// to the parent process when the actor starts up.
/// 
/// The `actor.start_spec` function gives us more fine-grained
/// control over how the actor gets created. We get to
/// provide a startup function to produce the initial state,
/// instead of simply providing the initial state directly.
/// 
/// We'll take advantadge of getting the chance to compute
/// things on the new process to send ourselves back a subject
/// for the actor.
/// 
/// This isn't a hack, it's the intended design. The subject
/// produced by the `actor.start_spec` function is for the
/// supervisor to use, not for us to use directly.
pub fn start(
  _input: Nil,
  parent_subject: Subject(Subject(Message)),
) -> Result(Subject(Message), actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() {
      // Create a new subject and send it to the parent process,
      // so that the parent process can send us messages.
      let actor_subject = process.new_subject()
      process.send(parent_subject, actor_subject)

      // Initialize the actor.
      // Notice we provide a selector rather than a simple subject.
      //
      // We can send out multiple subjects on startup if we want, 
      // so the actor can be communicated with from multiple processes.
      // The selector allows us to handle messages as they come in, no
      // matter which subject they were sent to.
      //
      // In our case, we only send out the one subject though.

      let selector =
        process.new_selector()
        |> process.selecting(actor_subject, function.identity)

      actor.Ready(Nil, selector)
    },
    // You might call other processes to start up your actor,
    // so we set a timeout to prevent the supervisor from
    // waiting forever for the actor to start.
    init_timeout: 1000,
    // This is the function that will be called when the actor
    // get's sent a message. We'll define it below.
    loop: handle_message,
  ))
}

/// We provide this function in case we want to manually stop the actor,
/// but in reality the supervisor will handle that for us.
pub fn shutdown(subject: Subject(Message)) -> Nil {
  actor.send(subject, Shutdown)
}

/// This is how we play the game.
/// We are at the whim of the child as to whether we are a 
/// humble duck or the mighty goose.
pub fn play_game(
  subject: Subject(Message),
) -> Result(String, process.CallError(String)) {
  let msg_generator = random.weighted(#(9.0, Duck), [#(1.0, Goose)])
  let msg = random.random_sample(msg_generator)

  process.try_call(subject, msg, 1000)
}

/// This is the type of messages that the actor will receive.
/// Remember, any time we want to reply to a message, that message
/// must contain a subject to reply with.
pub type Message {
  Duck(client: Subject(String))
  Goose(client: Subject(String))
  Shutdown
}

/// And finally, we play the game
fn handle_message(message: Message, _state: Nil) -> actor.Next(Message, Nil) {
  case message {
    Duck(client) -> {
      actor.send(client, "duck")
      actor.continue(Nil)
    }
    Goose(_) -> panic as "Oh shit it's a fucking goose!!!!"
    Shutdown -> actor.Stop(process.Normal)
  }
}
