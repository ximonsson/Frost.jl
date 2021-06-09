using Dates, DataFrames, HTTP, JSON3, StructTypes, TimeZones

struct Point
	type::String
	coordinates::Vector{Float64}
	nearest::Bool
end

StructTypes.StructType(::Type{Point}) = StructTypes.Struct()

StructTypes.names(::Type{Point}) = (
	(:type, Symbol("@type")),
	(:coordinates, :coordinates),
)

struct Source
	type::Union{String,Nothing}
	ID::Union{String,Nothing}
	name::Union{String,Nothing}
	short_name::Union{String,Nothing}
	country::Union{String,Nothing}
	country_code::Union{String,Nothing}
	wmo_id::Union{Int,Nothing}
	geometry::Union{Point,Nothing}
	distance::Union{Dict,Nothing}
	masl::Union{Int,Nothing}
	valid_from::Union{String,Nothing}
	valid_to::Union{String,Nothing}
	county::Union{String,Nothing}
	county_id::Union{Int,Nothing}
	municipality::Union{String,Nothing}
	municipality_id::Union{Int,Nothing}
	station_holders::Union{Vector{String},Nothing}
	external_ids::Union{Vector{String},Nothing}
	icao_codes::Union{Vector{String},Nothing}
	ship_codes::Union{Vector{String},Nothing}
	wigos_id::Union{String,Nothing}
end

StructTypes.StructType(::Type{Source}) = StructTypes.Struct()

StructTypes.names(::Type{Source}) = (
	(:type, Symbol("@type")),
	(:ID, :id),
	(:name, :name),
	(:short_name, :shortName),
	(:country, :country),
	(:country_code, :countryCode),
	(:wmo_id, :wmoId),
	(:geometry, :geometry),
	(:distance, :distance),
	(:masl, :masl),
	(:valid_from, :validFrom),
	(:valid_to, :validTo),
	(:county, :county),
	(:county_id, :countyId),
	(:municipality, :municipality),
	(:municipality_id, :municipalityId),
	(:station_holders, :stationHolders),
	(:external_ids, :externalIds),
	(:icao_codes, :icaoCodes),
	(:ship_codes, :shipCodes),
	(:wigos_id, :wigosId),
)

function DataFrames.DataFrame(s::Source)
	#
	# some columns point to vectors, mark these as "special"
	# they will be joined to one string
	#

	special_fields = [:station_holders, :external_ids, :icao_codes, :ship_codes]

	special_fn(f) = getfield(s, f) |> isnothing ? f => missing : f => join(getfield(s, f), ";")

	#
	# create columns for DataFrame
	#

	# non-special columns
	fs = filter(
		∉([special_fields; :geometry],),
		fieldnames(Source),
	)

	# ordinary columns
	cols = [x => y for (x, y) in zip(
		fs, map(f -> something(getfield(s, f), missing), fs)
	)]

	# special columns
	append!(cols, map(
		special_fn,
		special_fields,
	))

	# geometry
	append!(
		cols,
		s.geometry |> !isnothing ?
			[:lat => s.geometry.coordinates[1], :lon => s.geometry.coordinates[2]] :
			[:lat => missing, :lon => missing]
	)

	return cols |> DataFrame
end

struct SourceResponse
	context::Union{String,Nothing}
	type::Union{String,Nothing}
	api_version::Union{String,Nothing}
	license::Union{String,Nothing}
	created_at::Union{ZonedDateTime,Nothing}
	query_time::Union{Float32,Nothing}
	current_item_count::Union{Int,Nothing}
	items_per_page::Union{Int,Nothing}
	offset::Union{Int,Nothing}
	total_item_count::Union{Int,Nothing}
	next_link::Union{String,Nothing}
	prev_link::Union{String,Nothing}
	current_link::Union{String,Nothing}
	data::Union{Vector{Source},Nothing}
end

StructTypes.StructType(::Type{SourceResponse}) = StructTypes.Struct()

StructTypes.names(::Type{SourceResponse}) = (
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

DataFrames.DataFrame(s::SourceResponse) = mapreduce(DataFrame, vcat, s.data)

const CLIENT_ID = ENV["CLIENT_ID"]
const CLIENT_SECRET = ENV["CLIENT_SECRET"]

function sources(IDs = "", types = "")
	r = HTTP.request("GET", "https://$CLIENT_ID:@frost.met.no/sources/v0.jsonld")
	JSON3.read(String(r.body), SourceResponse, dateformat = dateformat"yyyy-mm-ddTHH:MM:SSzzz")
end
