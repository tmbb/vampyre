defmodule Vampyre.HTML.DefaultEngine do
  @moduledoc false

  use EEx.Engine

  require Vampyre.HTML.Engine.Segment, as: Segment

  @doc false
  def init(_opts) do
    Segment.container([])
  end

  @doc false
  def handle_begin(Segment.container() = _state) do
    Segment.container([])
  end

  @doc false
  def handle_end(Segment.container() = container) do
    Segment.reverse_contents(container)
  end

  @doc false
  def handle_body(Segment.container() = container) do
    Segment.reverse_contents(container)
  end

  def handle_text(Segment.container() = container, text) do
    new_segment = Segment.static(text, [])
    Segment.prepend_to_contents(container, new_segment)
  end

  def handle_expr(Segment.container() = container, "=", expr) do
    line = line_from_expr(expr)
    expr = convert_assigns(expr)

    new_segment = Segment.dynamic(expr, line: line)
    Segment.prepend_to_contents(container, new_segment)
  end

  def handle_expr(Segment.container() = container, "", expr) do
    line = line_from_expr(expr)
    expr = convert_assigns(expr)

    new_segment = Segment.support(expr, line: line)
    Segment.prepend_to_contents(container, new_segment)
  end

  defp line_from_expr({_, meta, _}) when is_list(meta), do: Keyword.get(meta, :line)
  defp line_from_expr(_), do: nil

  defp convert_assigns(expr) do
    Macro.prewalk(expr, &handle_assign/1)
  end

  defp handle_assign({:@, meta, [{name, _, atom}]}) when is_atom(name) and is_atom(atom) do
    quote line: meta[:line] || 0 do
      Vampyre.HTML.DefaultEngine.fetch_assign(var!(assigns), unquote(name))
    end
  end

  defp handle_assign(arg), do: arg

  @doc false
  def fetch_assign(assigns, key) do
    case Access.fetch(assigns, key) do
      {:ok, val} ->
        val

      :error ->
        raise ArgumentError,
          message: """
          assign @#{key} not available in eex template.

          Please make sure all proper assigns have been set. If this
          is a child template, ensure assigns are given explicitly by
          the parent template as they are not automatically forwarded.

          Available assigns: #{inspect(Enum.map(assigns, &elem(&1, 0)))}
          """
    end
  end
end
