//// The most common concurrency abstraction one might reach for in
//// Gleam is the "actor". It is the type safe equivalent of the GenServer
//// concept in Erlang and Elixir.
//// If you want to have a process that can act as a "server", an actor is
//// probably what you want. 
//// The [stdlib docs for working with actors](https://hexdocs.pm/gleam_otp/gleam/otp/actor.html) are very good.
//// 

import actors/pantry

pub fn main() {
  // To demonstrate what actors are and how they work, we'll create a simple
  // "pantry" application based on a set data structure. 
  // You could easily build this with good old fashioned processes and messages,
  // but actors provide a common interface for long running processes that hold some state.
  // 
  // That being said, it's usually good practice to wrap up your actors in a public
  // API, and cordon off the concurrency concepts to your current module. Your users shouldn't
  // have to know that you're using actors under the hood.

  // This section will showcase the usage of our pantry.

  // In a real application, `open_pantry` might get the current contents of the pantry from
  // a database, but for this example the pantry will always start out empty
  let assert Ok(pantry) = pantry.new()

  // Trying to remove an item from an empty pantry should return an error
  let assert Error(_) = pantry.take_item(pantry, "flour")

  // Adding an item to the pantry will never error
  pantry.add_item(pantry, "flour")
  pantry.add_item(pantry, "sugar")

  // We should be able to get some flour out of the pantry now.
  let assert Ok("flour") = pantry.take_item(pantry, "flour")

  // We're done with the pantry now, so we'll close it.
  // (If you're wondering what happens if we forget to close our pantry, don't worry, we'll get there.)
  pantry.close(pantry)
  // Now that we've seen how to use the pantry, let's take a look at how it's implemented.
  // Check out the `pantry.gleam` file in the `actors` directory to see the implementation.
}
