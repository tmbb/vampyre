defmodule Vampyre.HTML.Engine.Compiler do
  require Vampyre.HTML.Engine.Segment, as: Segment
  alias Vampyre.HTML.Engine.Optimizer
  alias Vampyre.HTML.Engine.Compiler.{PreparedSegment, Escape, Group}

  @cursor_prefix "tmp"

  defp to_safe(Segment.segment(expr, _meta) = segment) do
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

  def group_to_html_result(%Group{segments: prepared_segments}) do
    filtered =
      Enum.filter(prepared_segments, fn s ->
        s.appears_in_result? == true
      end)

    mapped = Enum.map(filtered, &prepared_segment_to_result/1)

    case mapped do
      [] -> []
      [filtered] -> [filtered]
      list when is_list(list) -> [list]
    end
  end

  def groups_to_html_result(groups) do
    Enum.flat_map(groups, &group_to_html_result/1)
  end

  # JSON
  def json_array(values) do
    [
      "\n[\n",
      values,
      "\n]\n"
    ]
  end

  def prepared_segment_to_json_result(prepared_segment) do
    prepared_segment
    |> prepared_segment_to_result()
    |> Escape.escape_json()
  end

  def group_to_json_result(%Group{type: :dynamic}), do: []

  def group_to_json_result(%Group{type: :static, segments: prepared_segments}) do
    result = Enum.map(prepared_segments, &prepared_segment_to_json_result/1)
    [["  \"", result, "\""]]
  end

  def maybe_add_dummy_groups([]), do: []

  def maybe_add_dummy_groups(groups) do
    first =
      case Enum.at(groups, 0) do
        %Group{type: :dynamic} -> [Group.dummy_static_group()]
        _ -> []
      end

    last =
      case Enum.at(groups, -1) do
        %Group{type: :dynamic} -> [Group.dummy_static_group()]
        _ -> []
      end

    first ++ groups ++ last
  end

  def groups_to_json_result(groups, _element_id_var) do
    contents =
      groups
      |> maybe_add_dummy_groups()
      |> Enum.flat_map(&group_to_json_result/1)
      |> Enum.intersperse(",\n")

    json_array(contents)
  end

  def segments_to_result(segments) do
    groups = Group.split_into_groups(segments)
    groups_to_html_result(groups)
  end

  def segments_to_html_result(segments, element_id_var) do
    groups = Group.split_into_groups(segments)
    segments = groups_to_html_result(groups)

    open_tag = [
      ~s'<span id="',
      element_id_var,
      ~s'">'
    ]

    close_tag = [
      ~s'</span>'
    ]

    [open_tag, segments, close_tag]
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

  @doc false
  def segments_to_json_result(prepared_segments, element_id_var) do
    groups = Group.split_into_groups(prepared_segments)

    [
      ~s'<script type="application/json" undead-id="',
      element_id_var,
      ~s'">',
      groups_to_json_result(groups, element_id_var),
      "</script>"
    ]
  end

  def compile_container(Segment.container(segments, _), cursor) do
    prepared_segments = PreparedSegment.prepare_all_for_full(segments, cursor)
    compile_block(prepared_segments)
  end

  def compile(expanded_ast) do
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

  def compile_for_initial_render(Segment.container(segments, _), opts) do
    cursor = Keyword.get(opts, :cursor, @cursor_prefix)

    prepared_segments =
      segments
      |> compile()
      |> PreparedSegment.prepare_all_for_full(cursor)

    assignments = segments_to_assignments(prepared_segments)

    element_id_var = Macro.var(:element_id, __MODULE__)
    html_result_segments = segments_to_html_result(prepared_segments, element_id_var)
    json_result_segments = segments_to_json_result(prepared_segments, element_id_var)

    result =
      :lists.flatten([
        html_result_segments,
        "\n\n",
        json_result_segments
      ])

    optimized_result = Optimizer.merge_binaries(result)

    quote do
      # Avoid the "`assign` not used" warnings
      _ = unquote(Macro.var(:assigns, nil))
      # Generate a unique id for the DOM element and corresponding JSON
      unquote(element_id_var) = Integer.to_string(:rand.uniform(4_294_967_296), 32)
      unquote_splicing(assignments)
      {:safe, unquote(optimized_result)}
    end
  end

  defp do_compile(Segment.container(segments, _), opts, fun) do
    cursor = Keyword.get(opts, :cursor, @cursor_prefix)

    segments
    |> compile()
    |> fun.(cursor)
    |> compile_block()
  end

  def compile_full(container, opts \\ []) do
    compile_for_initial_render(container, opts)
  end

  def compile_dynamic(container, opts \\ []) do
    do_compile(container, opts, &PreparedSegment.prepare_all_for_dynamic/2)
  end

  def compile_static(container, opts \\ []) do
    do_compile(container, opts, &PreparedSegment.prepare_all_for_static/2)
  end
end
