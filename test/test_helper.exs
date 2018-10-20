defmodule Defrenderer do
  alias Vampyre.HTML.Engine.Compiler

  defmacro defrenderer(name, filename) do
    quoted = Compiler.compile_file(filename, __CALLER__)

    quote do
      def unquote(name)(var!(assigns)) do
        unquote(quoted) |> Phoenix.HTML.safe_to_string()
      end
    end
  end
end

ExUnit.start()
