defmodule Homeworlds.Core.System do
  alias Homeworlds.Core.Pyramid
  @type t :: %__MODULE__{id: reference(), ships: %{Pyramid.id() => Pyramid.t()}, stars: %{Pyramid.id() => Pyramid.t()}}

  defstruct  [
    :id,
    :ships,
    :stars,
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

  @spec add_ship(t(), Pyramid.t(), Pyramid.owner()) :: t()
  def add_ship(%__MODULE__{ships: ships} = system, pyramid, owner) do
    new_ships = Map.put(ships, pyramid.id, Pyramid.to_ship(pyramid, owner))
    %__MODULE__{system| ships: new_ships}
  end

  @spec take_ship(t(), Pyramid.id()) :: {t(), Pyramid.t()}
  def take_ship(%__MODULE__{ships: ships} = system, ship_pyramid_id) do
    {ship_pyramid, new_ships} = Map.pop(ships, ship_pyramid_id)
    {%__MODULE__{system | ships: new_ships}, ship_pyramid}
  end

  @spec take_all_ships(t()) :: [Pyramid.t()]
  def take_all_ships(%__MODULE__{ships: ships} = system) do
    pyramids = Enum.map(ships, fn {_, pyramid} -> pyramid end)
    {%__MODULE__{system | ships: %{}}, pyramids}
  end

  @spec add_star(t(), Pyramid.t()) :: t()
  def add_star(%__MODULE__{stars: stars} = system, pyramid) do
    new_stars = Map.put(stars, pyramid.id, Pyramid.to_star(pyramid))
    %__MODULE__{system | stars: new_stars}
  end

  @spec take_star(t(), Pyramid.id()) :: {t(), Pyramid.t()}
  def take_star(%__MODULE__{stars: stars} = system, star_pyramid_id) do
   {pyramid, new_stars} = Map.pop(stars, star_pyramid_id)
   {%__MODULE__{system | stars: new_stars}, pyramid}
  end

  def generate_name() do
     name = Enum.random([:Alpha, :Beta, :Gamma, :Delta, :Epsilon])
     rand = :rand.uniform(1000)
     "#{name}-#{rand}"
  end
end
