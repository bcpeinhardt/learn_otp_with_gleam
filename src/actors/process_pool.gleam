import gleam/erlang/process
import gleam/list
import gleam/otp/actor

pub type Pool(a) = process.Subject(Msg(a))

pub type PoolError

// Spin up a process pool.
pub fn start_pool(max_concurrent_processes: Int) -> Result(Pool(a), actor.StartError) {
  let init_state = State(max: max_concurrent_processes, process_count: 0, backlog: [])
  actor.start(init_state, handle_msg)
}

// Do a task when there's availability and send me the result when it's done.
pub fn do_when_available(pool: Pool(a), send_result: fn(a) -> Nil, task: fn() -> a) {
  actor.send(pool, DoWhenAvailable(send_result:, task:))
}

pub fn shutdown(pool: Pool(a)) {
    actor.send(pool, Shutdown)
}

pub opaque type Msg(a) {
  DoWhenAvailable(send_result: fn(a) -> Nil, task: fn() -> a)
  TaskComplete
  Shutdown
}

type State {
  State(max: Int, process_count: Int, backlog: List(fn() -> Nil))
}

fn handle_msg(msg: Msg(a), state: State) -> actor.Next(Msg(a), State) {
  // Go through the queues backlog and fire off all the tasks we have room for
  // in separate processes
  let available = state.max - state.process_count
  let work = list.take(state.backlog, up_to: available)
  let state = State(..state, backlog: list.drop(state.backlog, available))

  work
  |> list.each(fn(work) {
    let self = process.new_subject()
    use <- process.start(linked: False)
    work()
    process.send(self, TaskComplete)
  })

  case msg {
    DoWhenAvailable(send_result:, task:) ->
      actor.continue(
        State(..state, backlog: [fn() { send_result(task()) }, ..state.backlog]),
      )
    TaskComplete -> actor.continue(State(..state, process_count: state.process_count - 1))
    Shutdown -> actor.Stop(process.Normal)
  }
}
