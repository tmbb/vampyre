defmodule Vampyre.HTML.Engine.Compiler do
  require Vampyre.HTML.Engine.Segment, as: Segment
  alias Vampyre.HTML.Engine.Optimizer
  alias Vampyre.HTML.DefaultEngine
  alias Vampyre.HTML.Engine.Compiler.{PreparedSegment, Escape, Group}
  require EEx

  @cursor_prefix "tmp"

  defp to_safe({_tag, {expr, _meta}} = segment) do
    line = Segment.line(segment)
    Escape.to_safe(expr, line)
  end

  def compile_segment(Segment.dynamic() = segment), do: to_safe(segment)

  def compile_segment(Segment.fixed() = segment), do: to_safe(segment)

  def compile_segment(Segment.support(expr, _meta) = _segment), do: expr

  def compile_segment(Segment.static(bin, _meta)), do: bin

  def segments_to_assignments(prepared_segments) do
    for prepared <- prepared_segments,
        prepared.appears_in_body? == true do
      expr = compile_segment(prepared.segment)

      if is_nil(prepared.variable) do
        expr
      else
        quote do
          unquote(prepared.variable) = unquote(expr)
        end
      end
    end
  end

  # HTML
  def prepared_segment_to_result(%PreparedSegment{variable: nil, segment: segment}) do
    compile_segment(segment)
  end

  def prepared_segment_to_result(%PreparedSegment{variable: variable})
      when not is_nil(variable) do
    variable
  end

  def segments_to_result(prepared_segments) do
    Enum.map(prepared_segments, &prepared_segment_to_result/1)
  end

  def compile_block(prepared_segments) do
    assignments = segments_to_assignments(prepared_segments)
    result = segments_to_result(prepared_segments)

    quote do
      # `assigments` a list of expression, so we must splice them
      unquote_splicing(assignments)
      # `result` is a literal list which we wan to include as the
      # "return" value of the block1
      {:safe, unquote(result)}
    end
  end

  def compile_for_initial_render(Segment.container(segments, _), opts) do
    cursor = Keyword.get(opts, :cursor, @cursor_prefix)

    prepared_segments =
      segments
      |> compile_expanded()
      |> PreparedSegment.prepare_all(cursor)

    assignments = segments_to_assignments(prepared_segments)
    result = segments_to_result(prepared_segments)

    quote do
      # Avoid the "`assigns` not used" warnings
      _ = var!(assigns)
      # Generate a unique id for the DOM element and corresponding JSON
      unquote_splicing(assignments)
      {:safe, unquote(result)}
    end
  end

  def compile_container(Segment.container(segments, _), cursor) do
    prepared_segments = PreparedSegment.prepare_all(segments, cursor)
    compile_block(prepared_segments)
  end

  def compile_expanded(expanded_ast) do
    {new_ast, _counter} =
      Macro.postwalk(expanded_ast, 1, fn ast_node, counter ->
        case ast_node do
          Segment.container() ->
            cursor = "#{@cursor_prefix}_#{counter}"
            undead_node = compile_container(ast_node, cursor)
            {undead_node, counter + 1}

          other ->
            {other, counter}
        end
      end)

    new_ast
  end

  def compile(string, env) do
    quoted = EEx.compile_string(string, engine: DefaultEngine)
    expanded = Macro.prewalk(quoted, &Macro.expand(&1, env))

    expanded
    |> compile_expanded()
  end
end
