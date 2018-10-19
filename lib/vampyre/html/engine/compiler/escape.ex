defmodule Vampyre.HTML.Engine.Compiler.Escape do
  @moduledoc false

  @anno (if :erlang.system_info(:otp_release) >= '19' do
           [generated: true]
         else
           [line: -1]
         end)

  def escape_json(literal) when is_binary(literal) do
    Phoenix.HTML.escape_javascript(literal)
  end

  def escape_json(expr) do
    quote do
      Phoenix.HTML.escape_javascript(unquote(expr))
    end
  end

  def to_safe({:safe, expr}, line) do
    quote line: line, do: unquote(expr)
  end

  def to_safe(literal, _line)
      when is_binary(literal) or is_atom(literal) or is_number(literal) do
    Phoenix.HTML.Safe.to_iodata(literal)
  end

  # We can do the work at runtime
  def to_safe(literal, line) when is_list(literal) do
    quote line: line, do: Phoenix.HTML.Safe.to_iodata(unquote(literal))
  end

  # We need to check at runtime and we do so by
  # optimizing common cases.
  def to_safe(expr, line) do
    # Keep stacktraces for protocol dispatch...
    fallback = quote line: line, do: Phoenix.HTML.Safe.to_iodata(other)

    # However ignore them for the generated clauses to avoid warnings
    quote @anno do
      case unquote(expr) do
        {:safe, data} -> data
        bin when is_binary(bin) -> Plug.HTML.html_escape_to_iodata(bin)
        other -> unquote(fallback)
      end
    end
  end
end
