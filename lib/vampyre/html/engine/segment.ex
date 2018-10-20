defmodule Vampyre.HTML.Engine.Segment do
  @container_tag Vampyre.HTML.Engine.Segment.Container
  @static_tag Vampyre.HTML.Engine.Segment.Segment.Static
  @dynamic_tag Vampyre.HTML.Engine.Segment.Segment.Dynamic
  @support_tag Vampyre.HTML.Engine.Segment.Support
  @fixed_tag Vampyre.HTML.Engine.Segment.Segment.Fixed

  defguard is_segment(segment)
           when tuple_size(segment) == 2 and tuple_size(elem(segment, 1)) == 2 and
                  elem(segment, 0) in [
                    @container_tag,
                    @static_tag,
                    @dynamic_tag,
                    @support_tag,
                    @fixed_tag
                  ]

  def line({_tag, {_contents, meta}}) do
    Keyword.get(meta, :line)
  end

  def reverse_contents({@container_tag, {segments, meta}}) do
    reversed_segments = :lists.reverse(segments)
    {@container_tag, {reversed_segments, meta}}
  end

  def prepend_to_contents({@container_tag, {contents, meta}}, new) do
    {@container_tag, {[new | contents], meta}}
  end

  def update({tag, {_old_contents, meta}}, new_contents) do
    {tag, {new_contents, meta}}
  end

  defmacro segment() do
    quote do
      {_tag, {_contents, _meta}}
    end
  end

  defmacro segment(tag, contents) do
    quote do
      {unquote(tag), {unquote(contents), _meta}}
    end
  end

  defmacro segment(tag, contents, meta) do
    quote do
      {unquote(tag), {unquote(contents), unquote(meta)}}
    end
  end

  defmacro container() do
    quote do
      {unquote(@container_tag), {_contents, _meta}}
    end
  end

  defmacro container(contents, meta \\ []) do
    quote do
      {unquote(@container_tag), {unquote(contents), unquote(meta)}}
    end
  end

  defmacro static() do
    quote do
      {unquote(@static_tag), {_contents, _meta}}
    end
  end

  defmacro static(contents, meta \\ []) do
    quote do
      {unquote(@static_tag), {unquote(contents), unquote(meta)}}
    end
  end

  defmacro dynamic() do
    quote do
      {unquote(@dynamic_tag), {_contents, _meta}}
    end
  end

  defmacro dynamic(contents, meta \\ []) do
    quote do
      {unquote(@dynamic_tag), {unquote(contents), unquote(meta)}}
    end
  end

  defmacro support() do
    quote do
      {unquote(@support_tag), {_contents, _meta}}
    end
  end

  defmacro support(contents, meta \\ []) do
    quote do
      {unquote(@support_tag), {unquote(contents), unquote(meta)}}
    end
  end

  defmacro fixed() do
    quote do
      {unquote(@fixed_tag), {_contents, _meta}}
    end
  end

  defmacro fixed(contents, meta \\ []) do
    quote do
      {unquote(@fixed_tag), {unquote(contents), unquote(meta)}}
    end
  end
end
