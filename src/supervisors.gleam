//// Alright time to learn about Supervisors
//// 

import gleam/io
import gleam/iterator
import gleam/otp/supervisor
import gleam/otp/actor
import gleam/erlang/process
import supervisors/a_shit_actor.{type Message} as duckduckgoose

pub fn main() {
  let parent_subject = process.new_subject()
  let game = supervisor.worker(duckduckgoose.start(_, parent_subject))

  let children = fn(children) {
    children
    |> supervisor.add(game)
  }

  let assert Ok(_supervisor_subject) = supervisor.start(children)
  let assert Ok(game_subject) = process.receive(parent_subject, 1000)

  // Good messages, nothing crashes
  io.debug(duckduckgoose.duck(game_subject))
  io.debug(duckduckgoose.duck(game_subject))
  io.debug(duckduckgoose.duck(game_subject))
  // // Oh shit, that aint good, our actors gonna crash
  // io.debug(duckduckgoose.goose(game_subject))

  // // No worries, supervisor turned things back on for us
  // process.sleep(10_000)
  // io.debug(duckduckgoose.duck(game_subject))
  // io.debug(duckduckgoose.duck(game_subject))
}
