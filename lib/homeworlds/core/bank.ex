defmodule Homeworlds.Core.Bank do
  @moduledoc """
  This module handles the bank, which holds the available pieces and accounts for their availability.
  """

  alias Homeworlds.Core.Pyramid
  alias Homeworlds.Core.Stash

  # TODO: Make this configurable and/or extend this list to support more colours

  defstruct [
    :stash
  ]

  @type t() :: %__MODULE__{stash: MapSet.t()}

  def new(options \\ []) do
    # %__MODULE__{
    #   stash: Stash.new(
    #     # TODO: Maybe refactor all_colours/0 to be owned by another module, it should become configurable too.
    #     for colour <- Pyramid.all_colours(), size <- Pyramid.all_sizes() do
    #       List.duplicate({colour, size}, 3) # TODO: make configurable number of stacks for each size/colour combination
    #     end
    #     |> List.flatten()
    #     |> Enum.map(fn {colour, size} -> Pyramid.new(colour, size) end)
    #   )
    # }

    %__MODULE__{
      stash:
        Stash.new(
          # TODO: Maybe refactor all_colours/0 to be owned by another module, it should become configurable too.
          [{:blue, 1}, {:yellow, 2}, {:green, 3}]
          |> List.flatten()
          |> Enum.map(fn {colour, size} -> Pyramid.new(colour, size) end)
        )
    }
  end

  def add_many(%__MODULE__{stash: stash}, pyramids) do
    new_stash =
      pyramids
      |> Enum.reduce(stash, fn pyramid, stash -> Stash.add(stash, pyramid) end)

    %__MODULE__{stash: new_stash}
  end

  def show_resources(%__MODULE__{stash: stash}) do
    Enum.group_by(stash.pyramids, fn pyramid -> pyramid.colour end, fn pyramid -> pyramid end)
  end

  def add(%__MODULE__{stash: stash} = bank, pyramid) do
    stash = Stash.add(stash, Pyramid.to_resource(pyramid))
    %__MODULE__{bank | stash: stash}
  end

  def take(%__MODULE__{} = bank, {colour, size}) do
    resources = show_resources(bank)

    case Enum.find(resources[colour], &(&1.size == size)) do
      nil ->
        {{:error, :unavailable_piece}, bank}

      pyramid ->
        take_by_id(bank, pyramid.id)
    end
  end

  def take_by_id(%__MODULE__{stash: stash} = bank, pyramid_id) do
    {pyramid, stash} = Stash.take(stash, pyramid_id)
    {pyramid, %__MODULE__{bank | stash: stash}}
  end

  def find(%__MODULE__{stash: stash} = _bank, pyramid_id) do
    if Stash.find(stash, pyramid_id) do
      :bank
    else
      false
    end
  end

  def has_piece?(%__MODULE__{stash: stash} = _banke, {colour, size}) do
    Stash.has_piece?(stash, {colour, size})
  end
end
