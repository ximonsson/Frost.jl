using Dates, DataFrames, HTTP, JSON

struct Point
	type::String
	coordinates::Vector{Float64}
end

struct Source
	type::String
	ID::String
	name::String
	short_name::String
	country::String
	country_code::String
	wmold::Dict
	geometry::Point
	distance::Dict
	masl::Dict
	valid_from::Date
	valid_to::Date
	county::String
	county_id::Int
	municipality::String
	municipality_id::Int
	station_holders::Vector{String}
	external_ids::Vector{String}
	icao_codes::Vector{String}
	ship_codes::Vector{String}
	wigos_id::String
end

function DataFrame(s::Source)

end

struct SourceResponse
	context::String
	type::String
	api_version::String
	license::String
	created_at::Date
	query_time::String
	current_item_count::Int
	items_per_page::Int
	offset::Int
	total_item_count::Int
	next_link::String
	prev_link::String
	current_link::String
	data::Vector{Source}
end

const CLIENT_ID = ENV["CLIENT_ID"]
const CLIENT_SECRET = ENV["CLIENT_SECRET"]

function sources(IDs = "", types = "")
	r = HTTP.request("GET", "https://$CLIENT_ID:@frost.met.no/sources/v0.jsonld")
	r.body |> String |> JSON.parse
end
