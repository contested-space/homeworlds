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

  @impl GenServer
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

  def create_game(opts \\ nil) do
    DynamicSupervisor.start_child(
      Homeworlds.Supervisor.GameSession,
      {__MODULE__, opts}
    )
  end

  def join_game(game_pid, player) do
    GenServer.call(game_pid, {:join, player})
  end

  def start_game(game_pid) do
    GenServer.call(game_pid, :start)
  end

  def get_board_state(game_session_pid) do
    GenServer.call(game_session_pid, :get_board_state)
  end

  def get_active_player(game_session_pid) do
    GenServer.call(game_session_pid, :get_active_player)
  end

  def finish_turn(game_session_pid) do
    GenServer.call(game_session_pid, :finish_turn)
  end

  def play_action(game_session_pid, action) do
    GenServer.call(game_session_pid, {:play_action, action})
  end

  @impl GenServer

  def handle_call({:join, player}, _from, %State{board: board} = state) do
    new_board = Board.add_player(board, player)
    {:reply, :ok, %State{state | board: new_board}}
  end

  def handle_call(:start, _from, %State{board: board} = state) do
    new_board = Board.start_game(board)
    {:reply, :ok, %State{state | board: new_board}}
  end

  def handle_call(:get_board_state, _from, %State{board: board} = state) do
    {:reply, board, state}
  end

  def handle_call(:get_active_player, _from, %State{board: board} = state) do
    result = Board.active_player(board)
    {:reply, result, state}
  end

  def handle_call(:finish_turn, _from, %State{board: board} = state) do
    new_board = Board.finish_turn(board)
    {:reply, :ok, %State{state | board: new_board}}
  end

  def handle_call({:play_action, action}, _from, %State{board: board} = state) do
    {result, new_board} = do_play_action(board, action)
    {:reply, result, %State{state | board: new_board}}
  end

  defp do_play_action(board, {:setup, %{piece: piece, role: role, destination: destination}}) do
    if Board.bank_has_piece?(board, piece) do
      case role do
        :ship ->
          {:ok,
           board
           |> Board.take_resource_from_bank(piece)
           |> Board.add_ship_to_system(destination, Board.active_player(board))}

        :star ->
          {:ok,
           board
           |> Board.take_resource_from_bank(piece)
           |> Board.add_star_to_system(destination)}
      end
    end
  end

  # defp do_play_action(board, {:trade, ... }) do

  # end

  # defp do_play_action(board, {:convert, ... }) do

  # end

  # defp do_play_action(board, {:move, ... }) do

  # end

  # defp do_play_action(board, {:explore, ... }) do

  # end

  # defp do_play_action(board, {:sacrifice, ... }) do

  # end
end
