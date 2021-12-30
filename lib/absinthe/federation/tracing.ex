defmodule Absinthe.Federation.Tracing do
  @moduledoc """
  Documentation for Absinthe.Federation.Tracing.
  """

  def version, do: 1

  defmacro __using__(_) do
    quote do
      def middleware(middleware, _, %{identifier: :subscription}), do: middleware

      def middleware(middleware, _, %{identifier: :mutation}),
        do: [Absinthe.Federation.Tracing.Middleware] ++ middleware

      def middleware(middleware, _, _),
        do: [Absinthe.Federation.Tracing.Middleware] ++ middleware
    end
  end
end
