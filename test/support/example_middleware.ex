defmodule Example.Middleware do
  @behaviour Absinthe.Middleware

  @impl true
  def call(%Absinthe.Resolution{} = res, _opts) do
    case res do
      %{arguments: %{item_id: item_id, __typename: "ItemWithModuleMiddleware"}} ->
        value = %{item_id: "ModuleMiddleware:#{item_id}", __typename: "ItemWithModuleMiddleware"}

        res
        |> Map.put(:value, value)
        |> Map.put(:state, :resolved)

      res ->
        res
    end
  end
end
