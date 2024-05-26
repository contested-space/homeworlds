defmodule Homeworlds.Boundary.GameManager do
  alias Homeworlds.Boundary.GameSession
  use GenServer

  defmodule State do
    defstruct games: []
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

  def create_game(opts \\ nil) do
    :erlang.whereis(__MODULE__)
    |> GenServer.call({:create_game, opts})
  end

  def find_game(game_id) when is_reference(game_id) do
    :erlang.whereis(__MODULE__)
    |> GenServer.call({:find_game, game_id})
  end

  def find_games_with_player(player) do
    :erlang.whereis(__MODULE__)
    |> GenServer.call({:find_games_with_player, player})
  end

  def join_game(game_id, player) do
    :erlang.whereis(__MODULE__)
    |> GenServer.call({:join_game, game_id, player})
  end

  @impl GenServer
  def handle_call({:create_game, _opts}, _from, %State{games: games} = state) do
    game_id = make_ref()
    {:ok, game_session_pid} = GameSession.start_game(%{game_id: game_id})
    info = %Info{players: [], game_id: game_id, session_pid: game_session_pid}
    {:reply, info, %State{state | games: [info | games]}}
  end

  def handle_call({:find_game, game_id}, _from, %State{} = state) do
    game_info = find_game_by_id(state, game_id)
    {:reply, game_info, state}
  end

  def handle_call({:find_games_with_player, player}, _from, %State{} = state) do
    games = find_games_by_player(state, player)
    {:reply, games, state}
  end

  def handle_call({:join_game, game_id, player}, _from, %State{} = state) do
    {%State{games: other_games} = state, %Info{players: players} = game_info} =
      pop_game_by_id(state, game_id)

    # TODO: validate result before adding player to game info
    result = GameSession.join_game(game_info.session_pid, player)

    new_game_info = %Info{game_info | players: [player | players]}

    {:reply, result, %State{state | games: [new_game_info | other_games]}}
  end

  def handle_call({:find_game_by_id, id}, _from, %State{games: games} = state) do
    pid =
      games
      |> Enum.find(&(&1.game_id == id))

    {:reply, pid, state}
  end

  defp pop_game_by_id(%State{games: games} = state, game_id) do
    game_info = find_game_by_id(state, game_id)
    other_games = List.delete(games, game_info)
    {%State{state | games: other_games}, game_info}
  end

  defp find_games_by_player(%State{games: games}, player) do
    games
    |> Enum.filter(&(player in &1.players))
  end

  defp find_game_by_id(%State{games: games}, game_id) do
    games
    |> Enum.find(&(&1.game_id == game_id))
  end
end
