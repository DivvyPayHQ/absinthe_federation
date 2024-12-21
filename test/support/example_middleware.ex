defmodule Example.Middleware do
  @behaviour Absinthe.Middleware

  @impl true
  def call(%{arguments: %{item_id: item_id, __typename: "ItemWithModuleMiddleware"}} = res, _opts) do
    value = %{item_id: "ModuleMiddleware:#{item_id}", __typename: "ItemWithModuleMiddleware"}
    Map.put(res, :value, value)
  end

  def call(res, _opts) do
    res
  end
end
