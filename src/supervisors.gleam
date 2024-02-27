//// Alright time to learn about Supervisors
//// 

import gleam/io
import gleam/iterator
import gleam/otp/supervisor
import gleam/otp/actor
import gleam/erlang/process
import supervisors/a_shit_actor.{type Message} as duckduckgoose

pub fn main() {
  let game = supervisor.worker(duckduckgoose.start)

  let children = fn(children) {
    children
    |> supervisor.add(game)
  }

  let assert Ok(_supervisor_subject) = supervisor.start(children)
  // Ok, how in the hell do I get this game subject.
}
