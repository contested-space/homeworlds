defmodule Homeworlds.Boundary.GameSession do
  use GenServer

  alias Homeworlds.Core.Board

  defmodule State do
    defstruct [
      :board
    ]
  end

  def child_spec(%{game_id: game_id} = opts) do
    %{
      id: {__MODULE__, game_id},
      start: {__MODULE__, :start_link, [opts]},
      restart: :temporary
    }
  end

  def init(_opts) do
    board = Homeworlds.Core.Board.new()
    {:ok, %State{board: board}}
  end

  def start_link(opts) do
    GenServer.start_link(
      __MODULE__,
      opts
    )
  end

  def start_game(opts \\ nil) do
    DynamicSupervisor.start_child(
      Homeworlds.Supervisor.GameSession,
      {__MODULE__, opts}
    )
  end

  def join_game(game_pid, player) do
    GenServer.call(game_pid, {:join, player})
  end

  def get_board_state(game_session_pid) do
    GenServer.call(game_session_pid, :get_board_state)
  end

  @impl GenServer

  def handle_call({:join, player}, _from, %State{board: board} = state) do
    new_board = Board.add_player(board, player)
    {:reply, :ok, %State{state | board: new_board}}
  end

  def handle_call(:get_board_state, _from, %State{board: board} = state) do
    {:reply, board, state}
  end
end
