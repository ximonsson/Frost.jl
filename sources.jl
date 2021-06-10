struct Source <: Data
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
	valid_from::Union{ZonedDateTime,Nothing}
	valid_to::Union{ZonedDateTime,Nothing}
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

function Base.NamedTuple(s::Source)
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

	return cols |> NamedTuple
end

function sources(IDs = "", types = "")
	query("/sources", Source)
end
