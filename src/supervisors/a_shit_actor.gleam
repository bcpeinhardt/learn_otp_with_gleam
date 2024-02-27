//// This module implements a shit actor that crashes every now and then.
//// Having an actor that fails every now and then will help us test out our supervisors.
//// It's also a nice refresher on actors. Read the code and make sure it makes sense.

import gleam/otp/actor
import gleam/erlang/process.{type Subject}
import prng/random

pub fn start(_input: Nil) -> Result(Subject(Message), actor.StartError) {
  actor.start(Nil, handle_message)
}

pub fn shutdown(subject: Subject(Message)) {
  actor.send(subject, Shutdown)
}

pub fn play_game(subject: Subject(Message)) -> String {
  let msg_generator = random.weighted(#(0.9, Duck), [#(0.1, Goose)])
  let msg = random.random_sample(msg_generator)
  actor.call(subject, msg, 1000)
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
