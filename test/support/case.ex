defmodule Absinthe.Federation.Case do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      use Plug.Test
      import ExUnit.Case
      import unquote(__MODULE__)
    end
  end

  def plug_parser(conn) do
    opts =
      Plug.Parsers.init(
        parsers: [:urlencoded, :multipart, :json, Absinthe.Plug.Parser],
        json_decoder: Jason
      )

    Plug.Parsers.call(conn, opts)
  end
end
