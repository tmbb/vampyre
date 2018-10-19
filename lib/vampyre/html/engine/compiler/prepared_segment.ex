defmodule Vampyre.HTML.Engine.Compiler.PreparedSegment do
  @moduledoc false
  require Vampyre.HTML.Engine.Segment, as: Segment

  defstruct segment: nil,
            appears_in_body?: nil,
            appears_in_result?: nil,
            variable: nil

  def new(fields) do
    struct(__MODULE__, fields)
  end

  def variable_for(Segment.static(), _cursor, _index), do: nil

  def variable_for(Segment.support(), _cursor, _index), do: nil

  def variable_for(Segment.dynamic(), cursor, index) do
    var_name = String.to_atom("#{cursor}_#{index}_dynamic")
    Macro.var(var_name, __MODULE__)
  end

  def variable_for(Segment.fixed(), cursor, index) do
    var_name = String.to_atom("#{cursor}_#{index}_fixed")
    Macro.var(var_name, __MODULE__)
  end

  def variable_for(Segment.container(), cursor, index) do
    var_name = String.to_atom("#{cursor}_#{index}_container")
    Macro.var(var_name, __MODULE__)
  end

  def appears_in_block_body?(segment) do
    case segment do
      Segment.static() -> false
      _ -> true
    end
  end

  # Results

  def appears_in_block_result?(segment) do
    case segment do
      Segment.support() -> false
      _ -> true
    end
  end

  @doc false
  def prepare_segment(segment, cursor, index) do
    new(
      segment: segment,
      variable: variable_for(segment, cursor, index),
      cursor: append_to_cursor(cursor, index),
      appears_in_body?: appears_in_block_body?(segment),
      appears_in_result?: appears_in_block_result?(segment)
    )
  end

  def prepare_all(segments, cursor) do
    segments
    |> Enum.with_index(1)
    |> Enum.map(fn {segment, index} -> prepare_segment(segment, cursor, index) end)
  end

  defp append_to_cursor(cursor, index) do
    "#{cursor}_#{index}"
  end
end
