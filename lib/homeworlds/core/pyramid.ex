defmodule Homeworlds.Core.Pyramid do
  @type id :: reference()
  @type colour :: :red | :blue | :yellow | :green
  @type size :: pos_integer()
  @type role :: :ship | :star | :resource
  @type owner :: any()
  @type t :: %__MODULE__{
          id: reference(),
          colour: colour(),
          size: size(),
          role: role(),
          owner: owner()
        }

  defstruct [
    :id,
    :colour,
    :size,
    :role,
    :owner
  ]

  @spec new(colour(), size()) :: t()
  def new(colour, size) do
    %__MODULE__{
      # id: make_ref(),
      id: generate_name(colour, size),
      colour: colour,
      size: size,
      role: :resource,
      owner: nil
    }
  end

  @spec to_ship(t(), owner()) :: t()
  def to_ship(%__MODULE__{} = pyramid, owner) do
    %__MODULE__{pyramid | role: :ship, owner: owner}
  end

  @spec to_star(t()) :: t()
  def to_star(%__MODULE__{} = pyramid) do
    %__MODULE__{pyramid | role: :star, owner: nil}
  end

  @spec to_resource(t()) :: t()
  def to_resource(%__MODULE__{} = pyramid) do
    %__MODULE__{pyramid | role: :resource, owner: nil}
  end

  # TODO: turn that and the colour type into macros
  @spec all_colours() :: [colour()]
  def all_colours() do
    [
      :red,
      :blue,
      :yellow,
      :green
    ]
  end

  # TODO: also turn this into macros
  @spec all_sizes() :: [size()]
  def all_sizes() do
    [1, 2, 3]
  end

  def generate_name(colour, size) do
    "#{size}-#{colour}-#{:rand.uniform(1000)}"
  end
end
