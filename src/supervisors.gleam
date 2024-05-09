//// Alright time to learn about Supervisors
//// 
//// OTP applications are structured as "supervision" trees.
//// There are two types of processes in a supervision tree:
//// 1. Workers (these are the leaf nodes of the tree, they do all work)
//// 2. Supervisors (parent nodes of the tree, they manage the lifecycle of their child nodes, 
////    starting, stopping, restarting, and brutally killing them if necessary)
//// Pretty straightforward, workers do work, supervisors supervise.
//// 
//// Ok, why is this good? 
//// The propoganda goes like this:
//// 
//// -----------------------------------------------------------------------------------------
//// 
//// There are two kinds of bugs in software: consistent bugs and transient bugs.
//// 
//// Consistent (aka reproducible) bugs are really common but easy to discover and fix.
//// Good testing (and in Gleam's case, a good type system) can help with this.
//// 
//// Transient bugs are more rare, but they are a pain to diagnose and fix, and so they
//// are often left in the codebase for a long time.
//// 
//// The best approach we have for fixing these bugs when we can't reproduce them is to 
//// turn the damn thing off and on again.
//// 
//// Turning your tv off and on again is lame, but doable.
//// Turning a running production system off and on again is a non starter.
//// 
//// This is where supervisors come in. They are designed to provide common sense strategies
//// for turning their child processes off and on again when they crash.
//// 
//// By designing our application as a tree of these supervisors and workers, we can turn
//// JUST THE BROKEN PART off and on again, while the rest of the system keeps on running.
//// 
//// A supervisor will "detect" what the broken part is by slowly restarting layers, starting 
//// at the smallest layer and incrementing its way up the tree, until everything works again.
//// 
//// This architecture plus the BEAM's ability to update code while it is still running
//// are why these technologies are so good at building fault-tolerant systems.
//// 
//// Systems with transient concurrency bugs still operate mostly correctly, and one
//// can debug and fix the broken part without taking the system down.
//// 
//// -----------------------------------------------------------------------------------------
////
//// Evangelism complete. I don't need to give you the "everything's a tradeoff, 
//// there's no free lunch" speech, right?
//// 
//// Ok, I should put my money where my mouth is and show you some code.
//// To show how this works in practice, we need to write a program that crashes EVERY NOW AND THEN.
//// Such a program has been written in `supervisors/a_shit_actor.gleam`. Go read that and then
//// come back here.
//// 
//// Back? Great, read on.

import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/otp/supervisor
import supervisors/a_shit_actor as duckduckgoose

pub fn main() {
  // Let's set up our supervisor tree.
  // This one will be really simple.
  // One worker (the game), and one supervisor.

  // We set up our worker, and we give the actor a subject for this process to send 
  // us messages with on init. Remember, it needs to send us back a subject so we 
  // can talk to it directly.
  let parent_subject = process.new_subject()
  let game = supervisor.worker(duckduckgoose.start(_, parent_subject))

  // The supervisor API is really simple. All a supervisor needs is a function
  // with which to intialize itself.
  // There's a `supervisor.start_spec` function as well for tuning the 
  // restart frequency and the initial state to pass to children.

  // We start the supervisor
  let assert Ok(_supervisor_subject) = supervisor.start(supervisor.add(_, game))

  // The actor's init function sent us a subject for us to be able
  // to send it messages
  let assert Ok(game_subject) = process.receive(parent_subject, 1000)

  // Let's play the game a bit
  play_game(parent_subject, game_subject, 100)
}

/// This function will play the duck duck goose game 100 times
/// (As in 100 chances to be a goose, not 100 geese total)
fn play_game(
  parent_subject: Subject(Subject(duckduckgoose.Message)),
  game_subject: Subject(duckduckgoose.Message),
  times n: Int,
) -> Nil {
  case n {
    // Base Case, recess is over
    0 -> Nil
    _ -> {
      case duckduckgoose.play_game(game_subject) {
        // We're just a normal old duck, so we keep playing
        Ok(msg) -> {
          io.println(msg)
          play_game(parent_subject, game_subject, n - 1)
        }

        // Oh no, a goose crashed our actor!
        Error(_) -> {
          io.println("Oh no, a goose crashed our actor!")

          // The supervisor should restart our actor for us,
          // but it'll be on a different process now! Don't 
          // worry though, the game's init function should
          // send us a new subject to use.
          let assert Ok(new_game_subject) =
            process.receive(parent_subject, 1000)

          // Keep playing the game with the new subject
          play_game(parent_subject, new_game_subject, n - 1)
        }
      }
    }
  }
}
// Run this module and checkout the output. You should get a couple crash reports,
// but the game should keep on running printing duck messages as well.
