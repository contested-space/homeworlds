defmodule Homeworlds.Boundary.GameManager do
  alias Homeworlds.Boundary.GameSession
  use GenServer

  defmodule State do
    defstruct [:games]
  end

  defmodule Info do
    defstruct [:players, :session_pid, :game_id]
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent
    }
  end

  @impl GenServer
  def init(_opts) do
    :erlang.register(__MODULE__, self())
    {:ok, %State{}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def create_game(player) do
    manager = :erlang.whereis(__MODULE__)
    GenServer.call(manager, {:create_game, player})
  end

  def find_game(game_id) do
    manager = :erlang.whereis(__MODULE__)

    GenServer.call(manager, {:find_game_by_id, game_id})
  end

  @impl GenServer
  def handle_call({:create_game, player}, _from, %State{games: games} = state) do
    game_id = make_ref()
    {:ok, game_session_pid} = GameSession.start_game(%{player: player, game_id: game_id})
    info = %Info{players: [player], game_id: game_id, session_pid: game_session_pid}
    {:reply, game_id, %State{state | games: [info | games]}}
  end

  def handle_call({:find_game_by_id, id}, _from, %State{games: games} = state) do
    pid =
      games
      |> Enum.find(&(&1.game_id == id))

    {:reply, pid, state}
  end
end
