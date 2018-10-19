defmodule Vampyre.HTML.Engine.CompilerTest do
  use ExUnit.Case, async: true
  alias Vampyre.HTML.Engine.Compiler
  import Defrenderer

  defrenderer(:render1, "test/templates/a.html.eex")
  defrenderer(:render2, "test/templates/static-dynamic-static.html.eex")

  test "test #1" do
    assert render1(a: 4) == "4"
    assert render2(dynamic: "abc") == "Static#1 abc Static#2"
  end
end
