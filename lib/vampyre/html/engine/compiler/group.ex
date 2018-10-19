# defmodule Vampyre.HTML.Engine.Compiler.Group do
#   @moduledoc """
#   Segments will be grouped into `Groups` in the UndeadTemplates.
#   """

#   alias Vampyre.HTML.Engine.Compiler.{PreparedSegment, Group}
#   require Vampyre.HTML.Engine.Segment, as: Segment

#   defstruct segments: [], type: nil

#   def new(opts) do
#     struct(Group, opts)
#   end

#   def dummy_static_group() do
#     prepared_segments = PreparedSegment.prepare_all_for_full([Segment.static("")], nil)
#     new(type: :static, segments: prepared_segments)
#   end

#   def for_segment(%PreparedSegment{segment: segment} = prepared_segment) do
#     type =
#       case segment do
#         Segment.static() -> :static
#         Segment.fixed() -> :static
#         Segment.dynamic() -> :dynamic
#         Segment.support() -> :dynamic
#       end

#     Group.new(segments: [prepared_segment], type: type)
#   end

#   defp prepend(%Group{segments: segments} = group, segment) do
#     %{group | segments: [segment | segments]}
#   end

#   defp reverse(%Group{segments: segments} = group) do
#     %{group | segments: Enum.reverse(segments)}
#   end

#   def split_into_groups([]), do: []

#   def split_into_groups([segment | segments]) do
#     group_segments(Group.for_segment(segment), segments)
#   end

#   # Current group is a group of static segments:

#   defp needs_new_group(group, segment, segments) do
#     [reverse(group) | group_segments(Group.for_segment(segment), segments)]
#   end

#   defp append_to_old_group(group, segment, segments) do
#     group |> prepend(segment) |> group_segments(segments)
#   end

#   # The current group is a static group
#   defp group_segments(%Group{type: :dynamic} = group, [
#          %PreparedSegment{segment: segment} = prepared_segment | segments
#        ]) do
#     case segment do
#       Segment.static() -> needs_new_group(group, prepared_segment, segments)
#       Segment.fixed() -> needs_new_group(group, prepared_segment, segments)
#       Segment.dynamic() -> append_to_old_group(group, prepared_segment, segments)
#       Segment.support() -> append_to_old_group(group, prepared_segment, segments)
#     end
#   end

#   # The current group is a dynamic group
#   defp group_segments(%Group{type: :static} = group, [
#          %PreparedSegment{segment: segment} = prepared_segment | segments
#        ]) do
#     case segment do
#       Segment.static() -> append_to_old_group(group, prepared_segment, segments)
#       Segment.fixed() -> append_to_old_group(group, prepared_segment, segments)
#       Segment.dynamic() -> needs_new_group(group, prepared_segment, segments)
#       Segment.support() -> needs_new_group(group, prepared_segment, segments)
#     end
#   end

#   # We've run out of segments
#   defp group_segments(group, []) do
#     [reverse(group)]
#   end
# end
