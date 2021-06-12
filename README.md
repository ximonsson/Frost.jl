# Frost.jl

**WIP**.

Julia interface towards the Norwegian meteorology institute's [Frost API](https://frost.met.no/api.html).


## Authentication

Before anything can be done you need a `CLIENT_ID` and a `CLIENT_SECRET` from [here](https://frost.met.no/auth/requestCredentials.html). Right now they need to be set as environment variables before loading the package or it will not load.


## Supported endpoints

* `/sources`
* `/observations/availableTimeSeries`
* `/observations`


## DataFrame Support

A crude DataFrames.jl support exists for all responses from the API. There are some nested fields where I have just taken some liberties.

Example:

```julia
using DataFrames

df = Frost.sources() |> DataFrame
```
