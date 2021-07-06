defmodule Absinthe.Federation.Notation do
  @moduledoc false

  defmacro __using__(_opts) do
    notations()
  end

  @spec notations() :: Macro.t()
  defp notations() do
    quote do
      import Absinthe.Federation.Notation, only: :macros
    end
  end

  defmacro key_fields(fields) when is_binary(fields) do
    quote do
      meta :key_fields, unquote(fields)
    end
  end

  defmacro external() do
    quote do
      meta :external, true
    end
  end

  defmacro requires_fields(fields) when is_binary(fields) do
    quote do
      meta :requires_fields, unquote(fields)
    end
  end

  defmacro provides_fields(fields) when is_binary(fields) do
    quote do
      meta :provides_fields, unquote(fields)
    end
  end

  defmacro extends() do
    quote do
      meta :extends, true
    end
  end
end
