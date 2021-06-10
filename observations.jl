struct Level
	level_type::String
	unit::String
	value::Real
end

StructTypes.StructType(::Type{Level}) = StructTypes.Struct()

StructTypes.names(::Type{Level}) = ((:level_type, :levelType),)

struct ObservationTimeSeries
	source_id::Union{String,Nothing}
	geometry::Union{Point,Nothing}
	level::Union{Level,Nothing}
	valid_from::Union{ZonedDateTime,Nothing}
	valid_to::Union{ZonedDateTime,Nothing}
	time_offset::Union{String,Nothing}
	time_resolution::Union{String,Nothing}
	time_series_id::Union{Int,Nothing}
	element_id::Union{String,Nothing}
	unit::Union{String,Nothing}
	code_table::Union{String,Nothing}
	performance_category::Union{String,Nothing}
	exposure_category::Union{String,Nothing}
	status::Union{String,Nothing}
	URI::Union{String,Nothing}
	user_group_ids::Union{Vector{Int},Nothing}
end

StructTypes.StructType(::Type{ObservationTimeSeries}) = StructTypes.Struct()

StructTypes.names(::Type{ObservationTimeSeries}) = (
	(:source_id, :sourceId),
	(:valid_from, :validFrom),
	(:valid_to, :validTo),
	(:time_offset, :timeOffset),
	(:time_resolution, :timeResolution),
	(:time_series_id, :timeSeriesId),
	(:element_id, :elementId),
	(:code_table, :codeTable),
	(:performance_category, :performanceCategory),
	(:exposure_category, :exposureCategory),
	(:URI, :uri),
	(:user_group_ids, :userGroupIds),
)

function Base.NamedTuple(o::ObservationTimeSeries)
	#
	# some columns point to vectors, mark these as "special"
	# they will be joined to one string
	#

	special_fields = [:user_group_ids]

	special_fn(f) = getfield(o, f) |> isnothing ? f => missing : f => join(getfield(o, f), ";")

	#
	# create columns for DataFrame
	#

	# non-special columns
	fs = filter(
		∉([special_fields; [:level, :geometry]],),
		fieldnames(ObservationTimeSeries),
	)

	# ordinary columns
	cols = [x => y for (x, y) in zip(
		fs, map(f -> something(getfield(o, f), missing), fs)
	)]

	# special columns
	append!(cols, map(
		special_fn,
		special_fields,
	))

	# geometry
	append!(
		cols,
		o.geometry |> !isnothing ?
			[:lat => s.geometry.coordinates[1], :lon => s.geometry.coordinates[2]] :
			[:lat => missing, :lon => missing]
	)

	# level
	append!(
		cols,
		o.level |> isnothing ?
			[:level_type => missing, :level_unit => missing, :level_value => missing] :
			[:level_type => o.level.level_type, :level_unit => o.level.unit, :level_value => o.level.value]
	)

	return cols |> NamedTuple
end

struct ObservationTimeSeriesResponse
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
	data::Union{Vector{ObservationTimeSeries},Nothing}
end

StructTypes.StructType(::Type{ObservationTimeSeriesResponse}) = StructTypes.Struct()

StructTypes.names(::Type{ObservationTimeSeriesResponse}) = (
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

DataFrames.DataFrame(r::ObservationTimeSeriesResponse) = map(NamedTuple, r.data) |> DataFrame

"""
	obsersaction_timeseries()

Find timeseries metadata by source and/or element.
"""
function observation_timeseries(sources = "", reference_time = "")
	r = HTTP.request("GET", "https://$CLIENT_ID:@frost.met.no/observations/availableTimeSeries/v0.jsonld")
	JSON3.read(
		String(r.body),
		ObservationTimeSeriesResponse,
		dateformat = dateformat"yyyy-mm-ddTHH:MM:SS.ssszzz",
	)
end


"""

	elementId (string, optional):

The ID of the element being observed. ,
value (string, optional):

The observed value (either a number or a UTC datetime of the format YYYY-MM-DD hh:mm:ss.sss). ,
origValue (string, optional):

The original observed value (either a number or a UTC datetime of the format YYYY-MM-DD hh:mm:ss.sss). ,
unit (string, optional):

The unit of measurement of the observed value. ,
codeTable (string, optional):

If the unit is a code, the codetable that describes the codes used. ,
level (Level, optional):

The vertical level at which the value was observed (if known). ,
timeOffset (string, optional):

The offset from referenceTime at which the observation applies. ,
timeResolution (string, optional):

The time between consecutive observations in the time series to which the observation belongs. ,
timeSeriesId (object, optional):

The internal ID of the time series to which the observation belongs. ,
performanceCategory (string, optional):

The performance category of the source when the value was observed. ,
exposureCategory (string, optional):

The exposure category of the source when the value was observed. ,
qualityCode (object, optional):

The quality control flag of the observed value. ,
controlInfo (string, optional):

The control info of the observed value. ,
dataVersion (object, optional):

The data version of the data value, if one exists (**Note: Currently not available for any observation data).

"""
struct Observation <: Data
	element_id::Union{String,Nothing}
	orig_value::Union{String,Nothing}
	code_table::Union{String,Nothing}
	level::Union{Level,Nothing}
	time_offset::Union{String,Nothing}
	time_resolution::Union{String,Nothing}
	time_series_id::Union{Int,Nothing}
	performance_category::Union{String,Nothing}
	exposure_category::Union{String,Nothing}
	quality_code::Union{Int,Nothing}
	control_info::Union{String,Nothing}
	data_version:Union{Int,Nothing}
end

StructTypes.StructType(::Type{Observation}) = StructTypes.Struct()

StructTypes.names(::Type{Observation}) = (
	(:element_id, :elementId),
	(:orig_value, :origValue),
	(:code_table, :codeTable),
	(:level, :level),
	(:time_offset, :timeOffset),
	(:time_resolution, :timeResolution),
	(:time_series_id, :timeSeriesId),
	(:performance_category, :performanceCategory),
	(:exposure_category, :exposureCategory),
	(:quality_code, :qualityCode),
	(:control_info, :controlInfo),
	(:data_version, :dataVersion),
)


"""
	observations(srcs, retime, els)

Get observation data from the Frost API.
"""
function observations(srcs, reftime, els)

end
