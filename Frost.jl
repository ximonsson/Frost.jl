module Frost

using Dates, DataFrames, HTTP, JSON3, StructTypes, TimeZones

const CLIENT_ID = ENV["CLIENT_ID"]
const CLIENT_SECRET = ENV["CLIENT_SECRET"]

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

include("sources.jl")
include("observations.jl")

end
