defmodule Homeworlds do
  @moduledoc """

  """
  alias Homeworlds.Boundary.GameManager

  defdelegate create_game(player), to: GameManager
  defdelegate join_game(game_id, player), to: GameManager
end
