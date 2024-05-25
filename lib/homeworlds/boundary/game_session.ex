defmodule Homeworlds.Boundary.GameSession do
  use GenServer

  defmodule State do
    defstruct [
      :board
    ]
  end

  def child_spec(%{player: player, game_id: game_id} = opts) do
    %{
      id: {__MODULE__, {player, game_id}},
      start: {__MODULE__, :start_link, [opts]},
      restart: :temporary
    }
  end

  def init(%{player: player} = _opts) do
    board = Homeworlds.Core.Board.new([player])
    {:ok, %State{board: board}}
  end

  def start_link(opts) do
    GenServer.start_link(
      __MODULE__,
      opts
    )
  end

  def start_game(opts) do
    DynamicSupervisor.start_child(
      Homeworlds.Supervisor.GameSession,
      {__MODULE__, opts}
    )
  end

  def get_board_state(game_session_pid) do
    GenServer.call(game_session_pid, :get_board_state)
  end

  @impl GenServer
  def handle_call(:get_board_state, _from, %State{board: board} = state) do
    {:reply, board, state}
  end
end
