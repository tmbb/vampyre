defmodule Defrenderer do
  alias Vampyre.HTML.Engine.Compiler

  defmacro defrenderer(name, filename) do
    string = File.read!(filename)
    quoted = Compiler.compile(string, __CALLER__)

    quote do
      def unquote(name)(var!(assigns)) do
        unquote(quoted) |> Phoenix.HTML.safe_to_string()
      end
    end
  end
end

ExUnit.start()
