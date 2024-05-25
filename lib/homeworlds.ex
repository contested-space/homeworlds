defmodule Homeworlds do
  @moduledoc """

  """
  alias Homeworlds.Boundary.GameManager
  alias Homeworlds.Boundary.GameSession

  def create_game(player) do
    GameManager.create_game(player)
  end
end
