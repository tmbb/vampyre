defmodule Vampyre.Template.EExEngine do
  @moduledoc """
  An engine suitable to use with Phoenix.
  """
  require Vampyre.HTML.Engine.Compiler, as: Compiler
  require Logger
  alias Vampyre.HTML.DefaultEngine
  alias Vampyre.Debug

  @behaviour Phoenix.Template.Engine

  @doc false
  defmacro __compile_with_env__(template_path, segments, _env) do
    expanded = Macro.prewalk(segments, &Macro.expand(&1, __CALLER__))
    compiled = Compiler.compile_expanded(expanded)

    if Debug.debug?() do
      Logger.info(~s'Template compiled using Vampyre: "#{template_path}"')
      Debug.dump_compiled_template_as_segments(template_path, segments)
      Debug.dump_compiled_template_as_quoted_expression(template_path, compiled)
      Debug.dump_compiled_template_as_code(template_path, compiled)
    end

    compiled
  end

  def compile(template_path, _template_name) do
    segments = EEx.compile_file(template_path, engine: DefaultEngine, line: 1, trim: true)

    quote do
      require Vampyre.Template.EExEngine

      Vampyre.Template.EExEngine.__compile_with_env__(
        unquote(template_path),
        unquote(segments),
        nil
      )
    end
  end
end
