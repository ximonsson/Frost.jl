struct Level
	level_type::String
	unit::String
	value::Real
end

StructTypes.StructType(::Type{Level}) = StructTypes.Struct()

StructTypes.names(::Type{Level}) = ((:level_type, :levelType),)

struct ObservationTimeSeries <: AbstractData
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
			[:lat => s.geometry.coordinates[2], :lon => s.geometry.coordinates[1]] :
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

"""
	observation_timeseries(
		sources = missing,
		ref_time = missing,
		els = missing,
		time_res = missing,
	)

Find timeseries metadata by source and/or element.
"""
function observation_timeseries(;
	srcs::Union{Missing,Union{AbstractString,AbstractVector{<:AbstractString}}} = missing,
	ref_time::Union{Missing,Pair{<:TimeType,:TimeType}} = missing,
	els::Union{Missing,Union{AbstractString,AbstractVector{<:AbstractString}}} = missing,
	time_res::Union{Missing,Union{AbstractString,AbstractVector{<:AbstractString}}} = missing,
)
	# formating functions
	fmt(δ::TimeType) = Dates.format(δ, "yyyy-mm-dd")
	fmt(s::AbstractString) = s
	fmt(v::Vector{<:AbstractString}) = join(v, ",")

	params = Pair{Symbol,String}[]

	if !ismissing(srcs)
		push!(params, :sources => fmt(srcs))
	end

	if !ismissing(ref_time)
		push!(params, :referencetime => fmt(reftime.first) * "/" * fmt(reftime.second))
	end

	if !ismissing(els)
		push!(params, :elements => fmt(els))
	end

	if !ismissing(time_res)
		push!(params, :timeresolutions => fmt(time_res))
	end

	query("/observations/availableTimeSeries", ObservationTimeSeries, params)
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

function Base.NamedTuple(o::Observation)
	#
	# some columns point to vectors, mark these as "special"
	# they will be joined to one string
	#

	special_fields = []

	special_fn(f) = getfield(o, f) |> isnothing ? f => missing : f => join(getfield(o, f), ";")

	#
	# create columns for DataFrame
	#
	# non-special columns

	fs = filter(
		∉([special_fields; [:level]],),
		fieldnames(Observation),
	)

	cols = [x => y for (x, y) in zip(
		fs, map(f -> something(getfield(o, f), missing), fs)
	)]

	# level
	append!(
		cols,
		o.level |> isnothing ?
			[:level_type => missing, :level_unit => missing, :level_value => missing] :
			[:level_type => o.level.level_type, :level_unit => o.level.unit, :level_value => o.level.value]
	)

	return cols |> NamedTuple
end

struct ObservationAtRefTime <: AbstractData
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

function Base.NamedTuple(o::ObservationAtRefTime)
	# fields
	fs = filter(
		∉([:geometry, :observations],),
		fieldnames(ObservationAtRefTime),
	)

	cols = [x => y for (x, y) in zip(
		fs, map(f -> something(getfield(o, f), missing), fs)
	)]

	# geometry
	append!(
		cols,
		o.geometry |> !isnothing ?
			[:lat => s.geometry.coordinates[2], :lon => s.geometry.coordinates[1]] :
			[:lat => missing, :lon => missing]
	)

	cols = cols |> NamedTuple

	return map(o -> merge(o |> NamedTuple, cols), o.observations)
end

"""
	observations(srcs, retime, els)

Get observation data from the Frost API.
"""
function observations(
	srcs::Union{AbstractString,AbstractVector{<:AbstractString}},
	reftime::Pair{<:TimeType,<:TimeType},
	els::Union{AbstractString,AbstractVector{<:AbstractString}},
	timeres::Union{Missing,Union{AbstractString,AbstractVector{<:AbstractString}}} = missing,
)
	# formating functions
	fmt(δ::TimeType) = Dates.format(δ, "yyyy-mm-dd")
	fmt(s::AbstractString) = s
	fmt(v::AbstractVector{<:AbstractString}) = join(fmt.(v), ",")

	params = [
		:sources => fmt(srcs),
		:referencetime => fmt(reftime.first) * "/" * fmt(reftime.second),
		:elements => fmt(els),
	]

	if !ismissing(timeres)
		params = [params; :timeresolutions => fmt(timeres)]
	end

	query("/observations", ObservationAtRefTime, params)
end
