defmodule Homeworlds.Core.Board do
  alias Homeworlds.Core.Bank
  alias Homeworlds.Core.System

  defstruct [
    :bank,
    :systems,
    :selected,
    :held_in_hand,
    players: [],
    turn_order: [],
    status: nil
  ]

  def new() do
    %__MODULE__{
      bank: Bank.new(),
      systems: [],
      selected: nil,
      held_in_hand: nil,
      turn_order: [],
      status: :created
    }
  end

  def add_player(%__MODULE__{players: players} = board, player) do
    %__MODULE__{board | players: [player | players]}
  end

  def start_game(%__MODULE__{players: players} = board) do
    turn_order = Enum.shuffle(players)
    %__MODULE__{board | turn_order: turn_order, status: :ongoing}
  end

  def active_player(%__MODULE__{turn_order: [active_player | _]}), do: active_player

  def finish_turn(%__MODULE__{turn_order: [active_player | other_players]} = board) do
    %__MODULE__{board | turn_order: other_players ++ [active_player]}
  end

  def find_origin(%__MODULE__{bank: bank, systems: systems} = _board, pyramid_id) do
    if Bank.find(bank, pyramid_id) do
      :bank
    else
      find_pyramid_in_systems(systems, pyramid_id)
    end
  end

  def find_pyramid_in_systems(systems, pyramid_id) do
    Enum.reduce_while(systems, false, fn system, acc ->
      case System.find(system, pyramid_id) do
        false -> {:cont, acc}
        val -> {:halt, val}
      end
    end)
  end

  # possible locations:
  # :bank
  # System.id
  # select_entity(board, location, id)

  def bank_has_piece?(%__MODULE__{bank: bank}, piece) do
    Bank.has_piece?(bank, piece)
  end

  def take_resource_from_bank(%__MODULE__{bank: bank, held_in_hand: nil} = board, pyramid_id) do
    {pyramid, new_bank} = Bank.take(bank, pyramid_id)
    %__MODULE__{board | bank: new_bank, held_in_hand: pyramid}
  end

  def add_resource_to_bank(%__MODULE__{bank: bank, held_in_hand: pyramid} = board) do
    new_bank = Bank.add(bank, pyramid)
    %__MODULE__{board | bank: new_bank, held_in_hand: nil}
  end

  # If a system is provided, select/2 replaces the existing selected system
  defp update_selected_system(%__MODULE__{} = board, %System{} = system) do
    %__MODULE__{board | selected: system}
  end

  # If a system_id is provided, a lookup is made on the board's systems
  # and if found, that system is moved into the selected field
  defp select_system(%__MODULE__{systems: systems} = board, system_id) do
    {system, other_systems} = list_pop(systems, &(&1.id == system_id))
    %__MODULE__{board | systems: other_systems, selected: system}
  end

  defp unselect_system(%__MODULE__{systems: systems, selected: nil} = board) do
    %__MODULE__{board | systems: systems}
  end

  defp unselect_system(%__MODULE__{systems: systems, selected: selected_system} = board) do
    %__MODULE__{board | systems: [selected_system | systems], selected: nil}
  end

  def add_ship_to_system(%__MODULE__{held_in_hand: pyramid} = board, system_id, owner)
      when not is_nil(pyramid) do
    board
    |> select_system(system_id)
    |> add_ship_to_selected_system(owner)
    |> unselect_system()
  end

  def add_ship_to_selected_system(
        %__MODULE__{held_in_hand: pyramid, selected: system} = board,
        owner
      ) do
    new_system = System.add_ship(system, pyramid, owner)
    %__MODULE__{board | selected: new_system, held_in_hand: nil}
  end

  def take_ship_from_system(%__MODULE__{held_in_hand: nil} = board, system_id, ship_pyramid_id) do
    board
    |> select_system(system_id)
    |> take_ship_from_selected_system(ship_pyramid_id)
    |> unselect_system()
  end

  def take_ship_from_selected_system(
        %__MODULE__{selected: system, held_in_hand: nil} = board,
        ship_pyramid_id
      ) do
    {pyramid, new_system} = System.take_ship(system, ship_pyramid_id)
    %__MODULE__{board | selected: new_system, held_in_hand: pyramid}
  end

  # If no system is selected, create a new one
  def add_star_to_system(board, system_id \\ nil)

  def add_star_to_system(
        %__MODULE__{systems: systems, held_in_hand: pyramid, selected: nil} = board,
        nil
      ) do
    new_system = System.new(pyramid)
    %__MODULE__{board | systems: [new_system | systems], held_in_hand: nil, selected: nil}
  end

  # If a system is selected, make it an n-ary system
  def add_star_to_system(%__MODULE__{held_in_hand: pyramid} = board, system_id)
      when not is_nil(pyramid) do
    board
    |> select_system(system_id)
    |> add_star_to_selected_system()
    |> unselect_system()
  end

  def add_star_to_selected_system(%__MODULE{held_in_hand: pyramid, selected: system} = board) do
    new_system = System.add_star(system, pyramid)

    board
    |> update_selected_system(new_system)
    |> empty_hand()
  end

  def hold_in_hand(%__MODULE__{held_in_hand: nil} = board, pyramid) do
    %__MODULE__{board | held_in_hand: pyramid}
  end

  def empty_hand(%__MODULE__{} = board) do
    %__MODULE__{board | held_in_hand: nil}
  end

  def take_star_from_system(%__MODULE__{} = board, system_id, star_pyramid_id) do
    board
    |> select_system(system_id)
    |> take_star_from_selected_system(star_pyramid_id)
    |> unselect_system()
  end

  def take_star_from_selected_system(%__MODULE__{selected: system} = board, star_pyramid_id) do
    case System.take_star(system, star_pyramid_id) do
      {pyramid, %System{stars: stars}} when map_size(stars) == 0 ->
        board
        |> hold_in_hand(pyramid)
        |> destroy_selected_system()
        |> unselect_system()

      {pyramid, new_system} ->
        board
        |> hold_in_hand(pyramid)
        |> update_selected_system(new_system)
    end
  end

  def destroy_selected_system(%__MODULE__{bank: bank, selected: system} = board) do
    {ships, _new_system} = System.take_all_ships(system)
    new_bank = Bank.add_many(bank, ships)
    %__MODULE__{board | bank: new_bank, selected: nil}
  end

  def generate_name() do
    :crypto.strong_rand_bytes(16)
  end

  # TODO: Deduplicate that and the one in Stash
  defp list_pop(list, fun) do
    case Enum.filter(list, fun) do
      [elem] ->
        new_list = List.delete(list, elem)
        {elem, new_list}

      _ ->
        {nil, list}
    end
  end
end
