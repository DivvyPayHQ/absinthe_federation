defmodule Example.Source do
  use Agent

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end

  def put(value) do
    Agent.update(__MODULE__, fn _ -> value end)
  end

  def run_batch({:one, ExampleItem, %{}}, items) do
    value = Agent.get(__MODULE__, & &1)

    for item <- items, into: %{} do
      {item, Map.get(value, item)}
    end
  end
end
