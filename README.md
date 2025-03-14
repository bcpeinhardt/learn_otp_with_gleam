# Learn OTP w/Gleam

### !! Work in Progress !!

Hello! I'm Ben, a software engineer who's fond of the [Gleam programming language](https://gleam.run/) interested in learning OTP. 

If you haven't heard:
- Gleam is a programming language that is statically typed, has great tooling, and an even better community.
- Gleam can compile to Erlang or JavaScript, depending on your needs. Because the concurrency models of these
  languages are fundamentally different, concurrency is handled at the library level.
- Erlang is sorta famous for its concurrency model, as well as it's standard framework for building
  concurrent applications: OTP. (Note: This isn't research stuff, Erlang is extremely battle tested.
  It runs a lot of places, and it was estimated in 2019 that "... 90% of all internet traffic (was) going through routers and switches controlled by Erlang." [source](https://www.erlang-solutions.com/blog/which-companies-are-using-erlang-and-why-mytopdogstatus/))
- Gleam has a package for using the OTP framework, called `gleam_otp`. It also has a package for more fundamental
  Erlang specific concepts, `gleam_erlang`.

I want to use these to build bad ass fault tolerant concurrent software!! But first, I need to learn OTP,
which means I'll be learning with resources written in Erlang and Elixir (neither of which are languages I'm overly experienced with if I'm honest).

While I go on this journey, I'm going to do my damndest to translate the things I learn to Gleam, and record
them here, so that in the future this repo might serve as the base for learning OTP with Gleam.

### Using this resource

This resource presumes A LOT of prerequisite knowledge in its users.
1. You kinda know what Erlang concurrency and OTP is about/why it's good. If you've yet to
   drink the Kool-aid, allow me to provide some:
  [The Soul of Erlang and Elixir talk](https://www.youtube.com/watch?v=JvBT4XBdoUE)
2. You are familiar w/Gleam syntax. Gleam has a very small set of language features that all work well together.
   It takes the idea of having only one way to do something pretty seriously, and as such is really quick
   to learn. If you have never seen Gleam, try out the [interactive tour](https://tour.gleam.run/), or follow
   the [Syllabus on Exercism](https://exercism.org/tracks/gleam/concepts).

Each section is broken into its own module (a top level file named <module_name>.gleam, and optionally a folder named <module_name> containing files for submodules). You can read them in the order
you like, but I recommend
1. concurrency_primitives
2. tasks
3. actors
4. supervisors

All the code in this project is runnable, just run `gleam run -m <module_name>`. Feel free to clone the repo
and tinker with the code!





