defmodule Vampyre.HTML.Engine.Optimizer do
  # This module doesn't do anything particularly complex.
  # It just applies some simple rules recursively on the nested templates.

  require Vampyre.HTML.Engine.Segment, as: Segment

  def merge_segments([]), do: []

  def merge_segments([s | rest]), do: merge_segments_helper(s, rest)

  def merge_segments_helper(
        Segment.static(bin1, meta1),
        [Segment.static(bin2, meta2) | rest]
      ) do
    merged = Segment.static(bin1 <> bin2, meta1 ++ meta2)
    merge_segments_helper(merged, rest)
  end

  def merge_segments_helper(
        Segment.static() = acc,
        [Segment.support() = support_segment | rest]
      ) do
    [support_segment | merge_segments_helper(acc, rest)]
  end

  def merge_segments_helper(current, [next | rest]) do
    [current | merge_segments_helper(next, rest)]
  end

  def merge_segments_helper(acc, []) do
    [acc]
  end

  def optimize_inside_container(Segment.container() = segment) do
    Segment.container(optimized_segments) = optimize_expr(segment)

    optimized_segments
    |> List.flatten()
    |> merge_segments()
  end

  def optimize_inside_container(expr) do
    optimize_expr(expr)
  end

  # TODO:
  # Try to replace this recursive implementation with somthing that uses `Macro.prewalk/2`.
  def optimize_expr(Segment.dynamic(Segment.container() = container, _meta)) do
    Segment.segment(optimized_segments, _meta) = optimize_expr(container)

    optimized_segments
  end

  def optimize_expr(Segment.container(segments, meta)) do
    non_optimized_segments = for segment <- segments, do: optimize_inside_container(segment)

    optimized_segments =
      non_optimized_segments
      |> List.flatten()
      |> merge_segments()

    Segment.container(optimized_segments, meta)
  end

  def optimize_expr(Segment.support() = segment) do
    segment
  end

  # Segments other than Segment.container()
  def optimize_expr(segment) when Segment.is_segment(segment) do
    Segment.segment(expr, _meta) = segment
    Segment.update(segment, optimize_expr(expr))
  end

  def optimize_expr(list) when is_list(list) do
    for expr <- list, do: optimize_expr(expr)
  end

  def optimize_expr({a, b}) do
    {optimize_expr(a), optimize_expr(b)}
  end

  def optimize_expr({f, meta, args}) do
    {f, meta, optimize_expr(args)}
  end

  def optimize_expr(other) do
    other
  end

  def macroexpand_template(template, env) do
    Macro.prewalk(template, &Macro.expand(&1, env))
  end

  def optimize(Segment.container() = template, env) do
    expanded = macroexpand_template(template, env)
    optimize_expr(expanded)
  end

  @spec merge_binaries(list()) :: list()
  def merge_binaries([]), do: []

  def merge_binaries([s | rest]), do: merge_binaries_helper(s, rest)

  defp merge_binaries_helper(bin1, [bin2 | rest]) when is_binary(bin1) and is_binary(bin2) do
    merge_binaries_helper(bin1 <> bin2, rest)
  end

  defp merge_binaries_helper(anything, [next | rest]) do
    [anything | merge_binaries_helper(next, rest)]
  end

  defp merge_binaries_helper(anything, []) do
    [anything]
  end
end
