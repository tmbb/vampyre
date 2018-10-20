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

  def merge_segments_helper(current, [next | rest]) do
    [current | merge_segments_helper(next, rest)]
  end

  def merge_segments_helper(acc, []) do
    [acc]
  end

  def optimize_inside_container(Segment.container() = segment) do
    Segment.container(optimized_segments) = optimize(segment)

    optimized_segments
    |> List.flatten()
    |> merge_segments()
  end

  def optimize_inside_container(expr) do
    optimize(expr)
  end

  # TODO:
  # Try to replace this recursive implementation with somthing that uses `Macro.prewalk/2`.
  def optimize(Segment.dynamic(Segment.container() = container, _meta)) do
    Segment.container(optimized_segments, _meta) = optimize(container)

    optimized_segments
  end

  def optimize(Segment.container(segments, meta)) do
    non_optimized_segments = for segment <- segments, do: optimize_inside_container(segment)

    optimized_segments =
      non_optimized_segments
      |> List.flatten()
      |> merge_segments()

    Segment.container(optimized_segments, meta)
  end

  # def optimize(Segment.support() = segment) do
  #   segment
  # end

  # Segments other than Segment.container()
  def optimize(segment) when Segment.is_segment(segment) do
    Segment.segment(_tag, expr, _meta) = segment
    Segment.update(segment, optimize(expr))
  end

  def optimize(list) when is_list(list) do
    for expr <- list, do: optimize(expr)
  end

  def optimize({a, b}) do
    {optimize(a), optimize(b)}
  end

  def optimize({f, meta, args}) do
    {f, meta, optimize(args)}
  end

  def optimize(other) do
    other
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
