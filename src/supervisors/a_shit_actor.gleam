//// This module implements a shit actor that crashes every now and then.
//// Having an actor that fails every now and then will help us test out our supervisors.
//// It's also a nice refresher on actors. Read the code and make sure it makes sense.

import gleam/otp/actor
import gleam/erlang/process.{type Subject}
import gleam/function

pub fn start(
  _input: Nil,
  parent_subject: Subject(Subject(Message)),
) -> Result(Subject(Message), actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let actor_subject = process.new_subject()
      process.send(parent_subject, actor_subject)
      actor.Ready(
        Nil,
        process.selecting(
          process.new_selector(),
          actor_subject,
          function.identity,
        ),
      )
    },
    init_timeout: 1000,
    loop: handle_message,
  ))
}

pub fn shutdown(subject: Subject(Message)) {
  actor.send(subject, Shutdown)
}

pub fn duck(
  subject: Subject(Message),
) -> Result(String, process.CallError(String)) {
  process.try_call(subject, Duck, 1000)
}

pub fn goose(
  subject: Subject(Message),
) -> Result(String, process.CallError(String)) {
  process.try_call(subject, Goose, 1000)
}

pub type Message {
  Duck(client: Subject(String))
  Goose(client: Subject(String))
  Shutdown
}

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
