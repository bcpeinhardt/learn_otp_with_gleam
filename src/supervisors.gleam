//// Alright time to learn about Supervisors
//// 

import gleam/io
import gleam/otp/supervisor
import gleam/erlang/process
import supervisors/a_shit_actor as duckduckgoose

pub fn main() {
  let parent_subject = process.new_subject()
  let game = supervisor.worker(duckduckgoose.start(_, parent_subject))

  let children = fn(children) {
    children
    |> supervisor.add(game)
  }

  // We start the supervisor
  let assert Ok(_supervisor_subject) = supervisor.start(children)

  // The actor's init function sent us a subject for us to be able
  // to send it messages
  let assert Ok(game_subject) = process.receive(parent_subject, 1000)

  // Good messages, nothing crashes
  let assert Ok("duck") = duckduckgoose.duck(game_subject)

  // Oh shit, that ain't good, our actor is gonna crash
  let assert Error(_) = duckduckgoose.goose(game_subject)

  // Don't worry, the supervisor restarted our actor, and the actor's
  // init function sent us back a subject owned by the new process.
  let assert Ok(new_game_subject) = process.receive(parent_subject, 1000)
  let assert Ok("duck") = duckduckgoose.duck(new_game_subject)

  // There will likely be an error report in your terminal, but don't worry
  // everythings still working fine. Check it out
  io.println("It's all good in the hood baby")
}
