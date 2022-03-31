defmodule Absinthe.Federation.Trace.CachePolicy.Scope do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  @type t :: integer | :UNKNOWN | :PUBLIC | :PRIVATE

  field :UNKNOWN, 0
  field :PUBLIC, 1
  field :PRIVATE, 2
end

defmodule Absinthe.Federation.Trace.HTTP.Method do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  @type t ::
          integer
          | :UNKNOWN
          | :OPTIONS
          | :GET
          | :HEAD
          | :POST
          | :PUT
          | :DELETE
          | :TRACE
          | :CONNECT
          | :PATCH

  field :UNKNOWN, 0
  field :OPTIONS, 1
  field :GET, 2
  field :HEAD, 3
  field :POST, 4
  field :PUT, 5
  field :DELETE, 6
  field :TRACE, 7
  field :CONNECT, 8
  field :PATCH, 9
end

defmodule Absinthe.Federation.Trace.CachePolicy do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          scope: Absinthe.Federation.Trace.CachePolicy.Scope.t(),
          max_age_ns: integer
        }
  defstruct [:scope, :max_age_ns]

  field :scope, 1, type: Absinthe.Federation.Trace.CachePolicy.Scope, enum: true
  field :max_age_ns, 2, type: :int64
end

defmodule Absinthe.Federation.Trace.Details.VariablesJsonEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Absinthe.Federation.Trace.Details do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          variables_json: %{String.t() => String.t()},
          operation_name: String.t()
        }
  defstruct [:variables_json, :operation_name]

  field :variables_json, 4,
    repeated: true,
    type: Absinthe.Federation.Trace.Details.VariablesJsonEntry,
    map: true

  field :operation_name, 3, type: :string
end

defmodule Absinthe.Federation.Trace.Error do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          message: String.t(),
          location: [Absinthe.Federation.Trace.Location.t()],
          time_ns: non_neg_integer,
          json: String.t()
        }
  defstruct [:message, :location, :time_ns, :json]

  field :message, 1, type: :string
  field :location, 2, repeated: true, type: Absinthe.Federation.Trace.Location
  field :time_ns, 3, type: :uint64
  field :json, 4, type: :string
end

defmodule Absinthe.Federation.Trace.HTTP.Values do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          value: [String.t()]
        }
  defstruct [:value]

  field :value, 1, repeated: true, type: :string
end

defmodule Absinthe.Federation.Trace.HTTP.RequestHeadersEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: Absinthe.Federation.Trace.HTTP.Values.t() | nil
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Absinthe.Federation.Trace.HTTP.Values
end

defmodule Absinthe.Federation.Trace.HTTP.ResponseHeadersEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: Absinthe.Federation.Trace.HTTP.Values.t() | nil
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Absinthe.Federation.Trace.HTTP.Values
end

defmodule Absinthe.Federation.Trace.HTTP do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          method: Absinthe.Federation.Trace.HTTP.Method.t(),
          host: String.t(),
          path: String.t(),
          request_headers: %{String.t() => Absinthe.Federation.Trace.HTTP.Values.t() | nil},
          response_headers: %{String.t() => Absinthe.Federation.Trace.HTTP.Values.t() | nil},
          status_code: non_neg_integer,
          secure: boolean,
          protocol: String.t()
        }
  defstruct [
    :method,
    :host,
    :path,
    :request_headers,
    :response_headers,
    :status_code,
    :secure,
    :protocol
  ]

  field :method, 1, type: Absinthe.Federation.Trace.HTTP.Method, enum: true
  field :host, 2, type: :string
  field :path, 3, type: :string

  field :request_headers, 4,
    repeated: true,
    type: Absinthe.Federation.Trace.HTTP.RequestHeadersEntry,
    map: true

  field :response_headers, 5,
    repeated: true,
    type: Absinthe.Federation.Trace.HTTP.ResponseHeadersEntry,
    map: true

  field :status_code, 6, type: :uint32
  field :secure, 8, type: :bool
  field :protocol, 9, type: :string
end

defmodule Absinthe.Federation.Trace.Location do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          line: non_neg_integer,
          column: non_neg_integer
        }
  defstruct [:line, :column]

  field :line, 1, type: :uint32
  field :column, 2, type: :uint32
end

defmodule Absinthe.Federation.Trace.Node do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          id: {atom, any},
          original_field_name: String.t(),
          type: String.t(),
          parent_type: String.t(),
          cache_policy: Absinthe.Federation.Trace.CachePolicy.t() | nil,
          start_time: non_neg_integer,
          end_time: non_neg_integer,
          error: [Absinthe.Federation.Trace.Error.t()],
          child: [Absinthe.Federation.Trace.Node.t()]
        }
  defstruct [
    :id,
    :original_field_name,
    :type,
    :parent_type,
    :cache_policy,
    :start_time,
    :end_time,
    :error,
    :child
  ]

  oneof :id, 0
  field :response_name, 1, type: :string, oneof: 0
  field :index, 2, type: :uint32, oneof: 0
  field :original_field_name, 14, type: :string
  field :type, 3, type: :string
  field :parent_type, 13, type: :string
  field :cache_policy, 5, type: Absinthe.Federation.Trace.CachePolicy
  field :start_time, 8, type: :uint64
  field :end_time, 9, type: :uint64
  field :error, 11, repeated: true, type: Absinthe.Federation.Trace.Error
  field :child, 12, repeated: true, type: Absinthe.Federation.Trace.Node
end

defmodule Absinthe.Federation.Trace.QueryPlanNode.SequenceNode do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          nodes: [Absinthe.Federation.Trace.QueryPlanNode.t()]
        }
  defstruct [:nodes]

  field :nodes, 1, repeated: true, type: Absinthe.Federation.Trace.QueryPlanNode
end

defmodule Absinthe.Federation.Trace.QueryPlanNode.ParallelNode do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          nodes: [Absinthe.Federation.Trace.QueryPlanNode.t()]
        }
  defstruct [:nodes]

  field :nodes, 1, repeated: true, type: Absinthe.Federation.Trace.QueryPlanNode
end

defmodule Absinthe.Federation.Trace.QueryPlanNode.FetchNode do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          service_name: String.t(),
          trace_parsing_failed: boolean,
          trace: Absinthe.Federation.Trace.t() | nil,
          sent_time_offset: non_neg_integer,
          sent_time: Google.Protobuf.Timestamp.t() | nil,
          received_time: Google.Protobuf.Timestamp.t() | nil
        }
  defstruct [
    :service_name,
    :trace_parsing_failed,
    :trace,
    :sent_time_offset,
    :sent_time,
    :received_time
  ]

  field :service_name, 1, type: :string
  field :trace_parsing_failed, 2, type: :bool
  field :trace, 3, type: Absinthe.Federation.Trace
  field :sent_time_offset, 4, type: :uint64
  field :sent_time, 5, type: Google.Protobuf.Timestamp
  field :received_time, 6, type: Google.Protobuf.Timestamp
end

defmodule Absinthe.Federation.Trace.QueryPlanNode.FlattenNode do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          response_path: [Absinthe.Federation.Trace.QueryPlanNode.ResponsePathElement.t()],
          node: Absinthe.Federation.Trace.QueryPlanNode.t() | nil
        }
  defstruct [:response_path, :node]

  field :response_path, 1,
    repeated: true,
    type: Absinthe.Federation.Trace.QueryPlanNode.ResponsePathElement

  field :node, 2, type: Absinthe.Federation.Trace.QueryPlanNode
end

defmodule Absinthe.Federation.Trace.QueryPlanNode.ResponsePathElement do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          id: {atom, any}
        }
  defstruct [:id]

  oneof :id, 0
  field :field_name, 1, type: :string, oneof: 0
  field :index, 2, type: :uint32, oneof: 0
end

defmodule Absinthe.Federation.Trace.QueryPlanNode do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          node: {atom, any}
        }
  defstruct [:node]

  oneof :node, 0
  field :sequence, 1, type: Absinthe.Federation.Trace.QueryPlanNode.SequenceNode, oneof: 0
  field :parallel, 2, type: Absinthe.Federation.Trace.QueryPlanNode.ParallelNode, oneof: 0
  field :fetch, 3, type: Absinthe.Federation.Trace.QueryPlanNode.FetchNode, oneof: 0
  field :flatten, 4, type: Absinthe.Federation.Trace.QueryPlanNode.FlattenNode, oneof: 0
end

defmodule Absinthe.Federation.Trace do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          start_time: Google.Protobuf.Timestamp.t() | nil,
          end_time: Google.Protobuf.Timestamp.t() | nil,
          duration_ns: non_neg_integer,
          root: Absinthe.Federation.Trace.Node.t() | nil,
          signature: String.t(),
          unexecutedOperationBody: String.t(),
          unexecutedOperationName: String.t(),
          details: Absinthe.Federation.Trace.Details.t() | nil,
          client_name: String.t(),
          client_version: String.t(),
          client_address: String.t(),
          client_reference_id: String.t(),
          http: Absinthe.Federation.Trace.HTTP.t() | nil,
          cache_policy: Absinthe.Federation.Trace.CachePolicy.t() | nil,
          query_plan: Absinthe.Federation.Trace.QueryPlanNode.t() | nil,
          full_query_cache_hit: boolean,
          persisted_query_hit: boolean,
          persisted_query_register: boolean,
          registered_operation: boolean,
          forbidden_operation: boolean
        }
  defstruct [
    :start_time,
    :end_time,
    :duration_ns,
    :root,
    :signature,
    :unexecutedOperationBody,
    :unexecutedOperationName,
    :details,
    :client_name,
    :client_version,
    :client_address,
    :client_reference_id,
    :http,
    :cache_policy,
    :query_plan,
    :full_query_cache_hit,
    :persisted_query_hit,
    :persisted_query_register,
    :registered_operation,
    :forbidden_operation
  ]

  field :start_time, 4, type: Google.Protobuf.Timestamp
  field :end_time, 3, type: Google.Protobuf.Timestamp
  field :duration_ns, 11, type: :uint64
  field :root, 14, type: Absinthe.Federation.Trace.Node
  field :signature, 19, type: :string
  field :unexecutedOperationBody, 27, type: :string
  field :unexecutedOperationName, 28, type: :string
  field :details, 6, type: Absinthe.Federation.Trace.Details
  field :client_name, 7, type: :string
  field :client_version, 8, type: :string
  field :client_address, 9, type: :string
  field :client_reference_id, 23, type: :string
  field :http, 10, type: Absinthe.Federation.Trace.HTTP
  field :cache_policy, 18, type: Absinthe.Federation.Trace.CachePolicy
  field :query_plan, 26, type: Absinthe.Federation.Trace.QueryPlanNode
  field :full_query_cache_hit, 20, type: :bool
  field :persisted_query_hit, 21, type: :bool
  field :persisted_query_register, 22, type: :bool
  field :registered_operation, 24, type: :bool
  field :forbidden_operation, 25, type: :bool
end

defmodule Absinthe.Federation.ReportHeader do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          graph_ref: String.t(),
          hostname: String.t(),
          agent_version: String.t(),
          service_version: String.t(),
          runtime_version: String.t(),
          uname: String.t(),
          executable_schema_id: String.t()
        }
  defstruct [
    :graph_ref,
    :hostname,
    :agent_version,
    :service_version,
    :runtime_version,
    :uname,
    :executable_schema_id
  ]

  field :graph_ref, 12, type: :string
  field :hostname, 5, type: :string
  field :agent_version, 6, type: :string
  field :service_version, 7, type: :string
  field :runtime_version, 8, type: :string
  field :uname, 9, type: :string
  field :executable_schema_id, 11, type: :string
end

defmodule Absinthe.Federation.PathErrorStats.ChildrenEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: Absinthe.Federation.PathErrorStats.t() | nil
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Absinthe.Federation.PathErrorStats
end

defmodule Absinthe.Federation.PathErrorStats do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          children: %{String.t() => Absinthe.Federation.PathErrorStats.t() | nil},
          errors_count: non_neg_integer,
          requests_with_errors_count: non_neg_integer
        }
  defstruct [:children, :errors_count, :requests_with_errors_count]

  field :children, 1,
    repeated: true,
    type: Absinthe.Federation.PathErrorStats.ChildrenEntry,
    map: true

  field :errors_count, 4, type: :uint64
  field :requests_with_errors_count, 5, type: :uint64
end

defmodule Absinthe.Federation.QueryLatencyStats do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          latency_count: [integer],
          request_count: non_neg_integer,
          cache_hits: non_neg_integer,
          persisted_query_hits: non_neg_integer,
          persisted_query_misses: non_neg_integer,
          cache_latency_count: [integer],
          root_error_stats: Absinthe.Federation.PathErrorStats.t() | nil,
          requests_with_errors_count: non_neg_integer,
          public_cache_ttl_count: [integer],
          private_cache_ttl_count: [integer],
          registered_operation_count: non_neg_integer,
          forbidden_operation_count: non_neg_integer
        }
  defstruct [
    :latency_count,
    :request_count,
    :cache_hits,
    :persisted_query_hits,
    :persisted_query_misses,
    :cache_latency_count,
    :root_error_stats,
    :requests_with_errors_count,
    :public_cache_ttl_count,
    :private_cache_ttl_count,
    :registered_operation_count,
    :forbidden_operation_count
  ]

  field :latency_count, 13, repeated: true, type: :sint64
  field :request_count, 2, type: :uint64
  field :cache_hits, 3, type: :uint64
  field :persisted_query_hits, 4, type: :uint64
  field :persisted_query_misses, 5, type: :uint64
  field :cache_latency_count, 14, repeated: true, type: :sint64
  field :root_error_stats, 7, type: Absinthe.Federation.PathErrorStats
  field :requests_with_errors_count, 8, type: :uint64
  field :public_cache_ttl_count, 15, repeated: true, type: :sint64
  field :private_cache_ttl_count, 16, repeated: true, type: :sint64
  field :registered_operation_count, 11, type: :uint64
  field :forbidden_operation_count, 12, type: :uint64
end

defmodule Absinthe.Federation.StatsContext do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          client_reference_id: String.t(),
          client_name: String.t(),
          client_version: String.t()
        }
  defstruct [:client_reference_id, :client_name, :client_version]

  field :client_reference_id, 1, type: :string
  field :client_name, 2, type: :string
  field :client_version, 3, type: :string
end

defmodule Absinthe.Federation.ContextualizedQueryLatencyStats do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          query_latency_stats: Absinthe.Federation.QueryLatencyStats.t() | nil,
          context: Absinthe.Federation.StatsContext.t() | nil
        }
  defstruct [:query_latency_stats, :context]

  field :query_latency_stats, 1, type: Absinthe.Federation.QueryLatencyStats
  field :context, 2, type: Absinthe.Federation.StatsContext
end

defmodule Absinthe.Federation.ContextualizedTypeStats.PerTypeStatEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: Absinthe.Federation.TypeStat.t() | nil
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Absinthe.Federation.TypeStat
end

defmodule Absinthe.Federation.ContextualizedTypeStats do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          context: Absinthe.Federation.StatsContext.t() | nil,
          per_type_stat: %{String.t() => Absinthe.Federation.TypeStat.t() | nil}
        }
  defstruct [:context, :per_type_stat]

  field :context, 1, type: Absinthe.Federation.StatsContext

  field :per_type_stat, 2,
    repeated: true,
    type: Absinthe.Federation.ContextualizedTypeStats.PerTypeStatEntry,
    map: true
end

defmodule Absinthe.Federation.FieldStat do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          return_type: String.t(),
          errors_count: non_neg_integer,
          count: non_neg_integer,
          requests_with_errors_count: non_neg_integer,
          latency_count: [integer]
        }
  defstruct [:return_type, :errors_count, :count, :requests_with_errors_count, :latency_count]

  field :return_type, 3, type: :string
  field :errors_count, 4, type: :uint64
  field :count, 5, type: :uint64
  field :requests_with_errors_count, 6, type: :uint64
  field :latency_count, 9, repeated: true, type: :sint64
end

defmodule Absinthe.Federation.TypeStat.PerFieldStatEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: Absinthe.Federation.FieldStat.t() | nil
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Absinthe.Federation.FieldStat
end

defmodule Absinthe.Federation.TypeStat do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          per_field_stat: %{String.t() => Absinthe.Federation.FieldStat.t() | nil}
        }
  defstruct [:per_field_stat]

  field :per_field_stat, 3,
    repeated: true,
    type: Absinthe.Federation.TypeStat.PerFieldStatEntry,
    map: true
end

defmodule Absinthe.Federation.Field do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          return_type: String.t()
        }
  defstruct [:name, :return_type]

  field :name, 2, type: :string
  field :return_type, 3, type: :string
end

defmodule Absinthe.Federation.Type do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          field: [Absinthe.Federation.Field.t()]
        }
  defstruct [:name, :field]

  field :name, 1, type: :string
  field :field, 2, repeated: true, type: Absinthe.Federation.Field
end

defmodule Absinthe.Federation.Report.TracesPerQueryEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: Absinthe.Federation.TracesAndStats.t() | nil
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Absinthe.Federation.TracesAndStats
end

defmodule Absinthe.Federation.Report do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          header: Absinthe.Federation.ReportHeader.t() | nil,
          traces_per_query: %{String.t() => Absinthe.Federation.TracesAndStats.t() | nil},
          end_time: Google.Protobuf.Timestamp.t() | nil
        }
  defstruct [:header, :traces_per_query, :end_time]

  field :header, 1, type: Absinthe.Federation.ReportHeader

  field :traces_per_query, 5,
    repeated: true,
    type: Absinthe.Federation.Report.TracesPerQueryEntry,
    map: true

  field :end_time, 2, type: Google.Protobuf.Timestamp
end

defmodule Absinthe.Federation.ContextualizedStats.PerTypeStatEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: Absinthe.Federation.TypeStat.t() | nil
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: Absinthe.Federation.TypeStat
end

defmodule Absinthe.Federation.ContextualizedStats do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          context: Absinthe.Federation.StatsContext.t() | nil,
          query_latency_stats: Absinthe.Federation.QueryLatencyStats.t() | nil,
          per_type_stat: %{String.t() => Absinthe.Federation.TypeStat.t() | nil}
        }
  defstruct [:context, :query_latency_stats, :per_type_stat]

  field :context, 1, type: Absinthe.Federation.StatsContext
  field :query_latency_stats, 2, type: Absinthe.Federation.QueryLatencyStats

  field :per_type_stat, 3,
    repeated: true,
    type: Absinthe.Federation.ContextualizedStats.PerTypeStatEntry,
    map: true
end

defmodule Absinthe.Federation.TracesAndStats do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          trace: [Absinthe.Federation.Trace.t()],
          stats_with_context: [Absinthe.Federation.ContextualizedStats.t()],
          internal_traces_contributing_to_stats: [Absinthe.Federation.Trace.t()]
        }
  defstruct [:trace, :stats_with_context, :internal_traces_contributing_to_stats]

  field :trace, 1, repeated: true, type: Absinthe.Federation.Trace
  field :stats_with_context, 2, repeated: true, type: Absinthe.Federation.ContextualizedStats
  field :internal_traces_contributing_to_stats, 3, repeated: true, type: Absinthe.Federation.Trace
end
