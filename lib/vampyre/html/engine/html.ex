defmodule Vampyre.HTML.Engine.HTML do
  @moduledoc """
  Utilities to escape HTML strings.
  """

  alias Plug.HTML

  @doc """
  Escape a value into HTML.

  Supports all types supported by `to_string/1`.

  We use ´Plug.HTML` to escape HTML strings.
  We want to be able to escape all static values, namely *binaries*, *atoms and *integers*,
  so we will convert them into binaries when appropriate.

  An important note about escaping HTML strings is that the escaped string won't contain quotes.
  This means that an escaped string surrounded by quotes is *always* a valid string.
  We can render an attribute value as `~s'"' <> HTML.html_escape(value) <> ~s'"'`.
  There is no need to escape inside of the quotes again.
  """
  def html_escape(value) when is_binary(value), do: HTML.html_escape(value)

  def html_escape(value), do: value |> to_string() |> HTML.html_escape()
end
