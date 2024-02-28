//// Tasks are one off processes meant to easily make synchronous work async.
//// They're really straightforward to use, just fire them off and check back later.

import gleam/io
import gleam/otp/task
import gleam/erlang
import gleam/erlang/process
import gleam/list
import gleam/int

pub fn main() {
  // Do a thing in a different process
  // Note that this task is eager, it will start immediately
  let handle =
    task.async(fn() {
      process.sleep(1000)
      io.println("Task is done")
    })

  // Do some other stuff while the task is running
  io.println("I will execute right away")

  // When you need the result, block until it's done
  task.await(handle, 1000)

  // Now that the task is done, we can do more stuff
  io.println("I won't execute until the task is done.")

  // There's a problem with the code above. If the task times out, 
  // the current process will panic! Most of the time, you don't want that.
  // You can use `task.try_await` to handle the timeout gracefully.

  let handle = task.async(fn() { process.sleep(2000) })

  case task.try_await(handle, 1000) {
    Ok(_) -> io.println("Task finished successfully")
    // This is the one that will execute
    Error(_) -> io.println("Task timed out!")
  }

  // By default task processes are "linked" to the current process.
  // This is a bidirectional link:
  // If the current process panics and shuts down, the task will too.
  // If the task panics and shuts down, the current process will too!.
  //
  // FOOTGUN ALERT!: `task.try_await` will only protect you from a timeout.
  // If the task panics, the current process will panic too!
  // If you're thinking "That's kinda shit, what if I want to handle panicked
  // processes gracefully?", well, OTP has amazing constructs for that
  // called supervisors. It'd rather you use those than roll your own
  // shitty version.
  //
  // If you REALLY want to handle crashing tasks yourself, there's a function
  // called [rescue](https://hexdocs.pm/gleam_erlang/gleam/erlang.html#rescue)
  // which takes any function and converts a panic into a result.
  // It's really meant for handling exceptions thrown in ffi erlang/elixir 
  // code though, you shouldn't need it when operating from the relative safety 
  // of Gleam land

  let assert Error(_) = erlang.rescue(fn() { panic })

  // And an example using it with tasks, shame on you for ignoring my sage advice.
  // See how I used `erlang.rescue` on the very inside? That's important.
  // Calling `task.await` on a process that panics will generate a timeout,
  // which will crash everything anyway.
  let assert Error(_) =
    task.await(task.async(fn() { erlang.rescue(fn() { panic }) }), 1000)

  // To be clear, we're talking about protecting you from weird hard to
  // uncover concurrency bugs and network issues. Gleam's static typing
  // and immutability will do a good job protecting you from the run of the 
  // mill index out of bounds/foo is undefined bullshit. 
  // Just have your task return a `Result`

  let handle = task.async(fn() { list.at([1, 2, 3], 99) })

  case task.await(handle, 1000) {
    Ok(val) -> io.println("The 100th item is" <> int.to_string(val))
    Error(Nil) -> io.println_error("The list has fewer than 100 items")
  }
}
