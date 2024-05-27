defmodule Homeworlds.Core.Stash do
  alias Homeworlds.Core.Pyramid

  @type t() :: %__MODULE__{pyramids: [Pyramid.t()]}

  defstruct [:pyramids]

  def new() do
    %__MODULE__{pyramids: []}
  end

  def new(pyramids) when is_list(pyramids) do
    %__MODULE__{pyramids: pyramids}
  end

  def find(%__MODULE__{pyramids: pyramids}, pyramid_id) do
    Enum.reduce_while(pyramids, false, fn pyramid, acc ->
      if pyramid.id == pyramid_id, do: {:halt, true}, else: {:cont, acc}
    end)
  end

  def add(%__MODULE__{pyramids: pyramids} = stash, pyramid) do
    %__MODULE__{stash | pyramids: [pyramid | pyramids]}
  end

  def take(%__MODULE__{pyramids: pyramids}, pyramid_id) do
    {pyramid, new_pyramids} = list_pop_take(pyramids, &(&1.id == pyramid_id))
    {pyramid, %__MODULE__{pyramids: new_pyramids}}
  end

  def has_piece?(%__MODULE__{pyramids: pyramids}, {colour, size}) do
    Enum.find(pyramids, &(&1.colour == colour and &1.size == size))
  end

  defp list_pop_take(list, fun) do
    [elem] = Enum.filter(list, fun)
    new_list = List.delete(list, elem)
    {elem, new_list}
  end
end
