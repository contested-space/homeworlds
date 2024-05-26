defmodule Homeworlds do
  @moduledoc """

  """
  alias Homeworlds.Boundary.GameManager

  defdelegate create_game(opts \\ nil), to: GameManager
  defdelegate join_game(game_id, player), to: GameManager

  defdelegate find_game(game_id), to: GameManager

  defdelegate find_games_with_player(player), to: GameManager
end
