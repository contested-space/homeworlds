defmodule Homeworlds.Core.System do
  alias Homeworlds.Core.Pyramid

  @type t :: %__MODULE__{
          id: reference(),
          ships: %{Pyramid.id() => Pyramid.t()},
          stars: %{Pyramid.id() => Pyramid.t()}
        }

  defstruct [
    :id,
    :ships,
    :stars
  ]

  @spec new(Pyramid.t()) :: t()
  def new(pyramid) do
    %__MODULE__{
      # id: make_ref(),
      id: generate_name(),
      ships: %{},
      stars: %{pyramid.id => pyramid}
    }
  end

  def find(%__MODULE__{id: id, ships: ships, stars: stars}, pyramid_id) do
    case {stars, ships} do
      {_, %{^pyramid_id => pyramid}} ->
        %{system_id: id, role: :ship, owner: pyramid.owner}

      {%{^pyramid_id => _pyramid}, _} ->
        %{system_id: id, role: :star}

      _ ->
        false
    end
  end

  # TODO: having the pyramid be responsable for knowing its owner is weird, I should refactor that
  @spec add_ship(t(), Pyramid.t(), Pyramid.owner()) :: t()
  def add_ship(%__MODULE__{ships: ships} = system, pyramid, owner) do
    new_ships = Map.put(ships, pyramid.id, Pyramid.to_ship(pyramid, owner))
    %__MODULE__{system | ships: new_ships}
  end

  @spec take_ship(t(), Pyramid.id()) :: {Pyramid.t(), t()}
  def take_ship(%__MODULE__{ships: ships} = system, ship_pyramid_id) do
    {ship_pyramid, new_ships} = Map.pop(ships, ship_pyramid_id)
    {ship_pyramid, %__MODULE__{system | ships: new_ships}}
  end

  @spec take_all_ships(t()) :: [Pyramid.t()]
  def take_all_ships(%__MODULE__{ships: ships} = system) do
    pyramids = Enum.map(ships, fn {_, pyramid} -> pyramid end)
    {pyramids, %__MODULE__{system | ships: %{}}}
  end

  @spec add_star(t() | nil, Pyramid.t()) :: t()
  def add_star(nil, pyramid) do
    new(pyramid)
  end

  def add_star(%__MODULE__{stars: stars} = system, pyramid) do
    new_stars = Map.put(stars, pyramid.id, Pyramid.to_star(pyramid))
    %__MODULE__{system | stars: new_stars}
  end

  @spec take_star(t(), Pyramid.id()) :: {t(), Pyramid.t()}
  def take_star(%__MODULE__{stars: stars} = system, star_pyramid_id) do
    {pyramid, new_stars} = Map.pop(stars, star_pyramid_id)
    {pyramid, %__MODULE__{system | stars: new_stars}}
  end

  def generate_name() do
    name = Enum.random([:Alpha, :Beta, :Gamma, :Delta, :Epsilon])
    rand = :rand.uniform(1000)
    "#{name}-#{rand}"
  end
end
