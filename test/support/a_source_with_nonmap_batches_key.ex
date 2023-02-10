defmodule ASourceWithNonmapBatchesKey do
  defstruct batches: []

  defimpl Dataloader.Source do
    def load(source, _batch_key, _item_key), do: source
    def run(source), do: source
    def fetch(_source, _batch_key, _item_key), do: {:ok, nil}
    def pending_batches?(_source), do: false
    def put(source, _batch_key, _item_key, _item), do: source
    def timeout(_source), do: 1000
  end
end
