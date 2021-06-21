abstract type AbstractData end

struct Response{T<:AbstractData}
	context::Union{String,Nothing}
	type::Union{String,Nothing}
	api_version::Union{String,Nothing}
	license::Union{String,Nothing}
	created_at::Union{String,Nothing}
	query_time::Union{Float32,Nothing}
	current_item_count::Union{Int,Nothing}
	items_per_page::Union{Int,Nothing}
	offset::Union{Int,Nothing}
	total_item_count::Union{Int,Nothing}
	next_link::Union{String,Nothing}
	prev_link::Union{String,Nothing}
	current_link::Union{String,Nothing}
	data::Union{Vector{T},Nothing}
end

StructTypes.StructType(::Type{Response{T}}) where T<:AbstractData = StructTypes.Struct()

StructTypes.names(::Type{Response{T}}) where T<:AbstractData = (
	(:context, Symbol("@context")),
	(:type, Symbol("@type")),
	(:api_version, :apiVersion),
	(:license, :license),
	(:created_at, :createdAt),
	(:query_time, :queryTime),
	(:current_item_count, :currentItemCount),
	(:items_per_page, :itemsPerPage),
	(:offset, :offset),
	(:total_item_count, :totalItemCount),
	(:next_link, :nextLink),
	(:prev_link, :prevLink),
	(:current_link, :currentLink),
	(:data, :data),
)

DataFrames.DataFrame(r::Response, args...; kwargs...) =
	DataFrame(reduce(vcat, map(NamedTuple, r.data)), args...; kwargs...)

"""
	query(endpoint::AbstractString, T::AbstractData)

Find timeseries metadata by source and/or element.
"""
function query(
	endpoint::AbstractString,
	T::Type{<:AbstractData},
	query::Vector{Pair{Symbol,String}} = Pair{Symbol,String}[],
	args...;
	kwargs...
)
	uri = HTTP.URI(
		scheme = "https",
		userinfo = "$CLIENT_ID:",
		host = "frost.met.no",
		path = "$endpoint/v0.jsonld",
		query = join(join.(query, "="), "&"),
	)

	r = HTTP.get(uri)

	JSON3.read(
		String(r.body),
		Response{T},
		dateformat = dateformat"yyyy-mm-ddTHH:MM:SS.ssszzz",
	)
end
