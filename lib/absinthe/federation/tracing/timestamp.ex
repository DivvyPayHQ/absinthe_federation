defmodule Absinthe.Federation.Tracing.Timestamp do
  @moduledoc """
  Helper functions for converting from elixir datetimes to protobuf timestamps and back.
  """
  alias Google.Protobuf.Timestamp

  @type unix_timestamp :: integer

  @nano_multiplier 1_000_000_000
  @utc "Etc/UTC"

  @doc """
  Convert a NaiveDateTime or a DateTime (while truncating timezone) to a Google.Protobuf.Timestamp
  """
  @spec serialize(NaiveDateTime.t() | DateTime.t() | nil) :: Timestamp.t() | nil
  def serialize(nil), do: nil

  def serialize(%NaiveDateTime{} = naive_datetime) do
    naive_datetime
    |> DateTime.from_naive!(@utc)
    |> serialize()
  end

  def serialize(%DateTime{} = datetime) do
    nanoseconds_since_epoch = DateTime.to_unix(datetime, :nanosecond)
    seconds = div(nanoseconds_since_epoch, @nano_multiplier)
    nanos = rem(nanoseconds_since_epoch, @nano_multiplier)

    Timestamp.new(seconds: seconds, nanos: nanos)
  end

  @doc """
  Convert a Google.Protobuf.Timestamp to a DateTime
  """
  @spec deserialize(Timestamp.t() | nil) :: DateTime.t() | nil
  def deserialize(nil), do: nil

  def deserialize(timestamp) do
    nanoseconds_since_epoch = timestamp.seconds * @nano_multiplier + timestamp.nanos

    nanoseconds_since_epoch
    |> DateTime.from_unix!(:nanosecond)
  end

  @spec now!() :: Timestamp.t()
  def now!(), do: @utc |> DateTime.now!() |> serialize()
end
