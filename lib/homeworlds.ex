defmodule Homeworlds do
  @moduledoc """

  """
  alias Homeworlds.Boundary.GameManager

  defdelegate create_game(opts \\ nil), to: GameManager
  defdelegate join_game(game_id, player), to: GameManager

  defdelegate start_game(game_id), to: GameManager

  defdelegate find_game(game_id), to: GameManager

  defdelegate get_active_player(game_id), to: GameManager

  defdelegate get_board_state(game_id), to: GameManager

  defdelegate finish_turn(game_id), to: GameManager

  defdelegate find_games_with_player(player), to: GameManager
end
