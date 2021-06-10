struct Level
	level_type::String
	unit::String
	value::Real
end

StructTypes.StructType(::Type{Level}) = StructTypes.Struct()

StructTypes.names(::Type{Level}) = ((:level_type, :levelType),)

struct ObservationTimeSeries <: Data
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

#StructTypes.StructType(::Type{Response{ObservationTimeSeries}}) = StructTypes.Struct()

"""
	obsersaction_timeseries()

Find timeseries metadata by source and/or element.
"""
function observation_timeseries(sources = "", reference_time = "")
	query("/observations/availableTimeSeries", ObservationTimeSeries)
end

struct Observation
	element_id::Union{String,Nothing}
	value::Union{Real,Nothing}
	orig_value::Union{Real,Nothing}
	unit::Union{String,Nothing}
	code_table::Union{String,Nothing}
	level::Union{Level,Nothing}
	time_offset::Union{String,Nothing}
	time_resolution::Union{String,Nothing}
	time_series_id::Union{Int,Nothing}
	performance_category::Union{String,Nothing}
	exposure_category::Union{String,Nothing}
	quality_code::Union{Int,Nothing}
	control_info::Union{String,Nothing}
	data_version::Union{Int,Nothing}
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

struct ObservationAtRefTime <: Data
	source_id::Union{String,Nothing}
	geometry::Union{Point,Nothing}
	ref_time::Union{ZonedDateTime,Nothing}
	observations::Vector{Observation}
end

StructTypes.StructType(::Type{ObservationAtRefTime}) = StructTypes.Struct()

StructTypes.names(::Type{ObservationAtRefTime}) = (
	(:source_id, :sourceId),
	(:ref_time, :referenceTime),
)

"""
	observations(srcs, retime, els)

Get observation data from the Frost API.
"""
function observations(srcs, reftime, els)
	query("/observations", ObservationAtRefTime, [:sources => srcs, :referencetime => reftime, :elements => els])
end
