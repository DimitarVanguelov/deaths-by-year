using HTTP
using DataFrames
using CSV

using Plots
using Plots.PlotMeasures
using PlotThemes
using Formatting

# ingest data
url1 = raw"https://data.cdc.gov/resource/3yf8-kanr.csv?$limit=50000"
url2 = raw"https://data.cdc.gov/resource/muzy-jte6.csv?$limit=50000"

df1 = CSV.read(HTTP.get(url1).body, DataFrame)
df2 = CSV.read(HTTP.get(url2).body, DataFrame)

rename!(df1, :allcause => :all_cause)

# keep only columns of interest at the moment
cols_to_keep = [
    :jurisdiction_of_occurrence,
    :mmwryear,
    :mmwrweek,
    :all_cause
]

# combine the two data sources into one dataframe
df3 = vcat(df1[:, cols_to_keep], df2[:, cols_to_keep])

# rename columns for easier use
cols_renamed = [
    :jurisdiction,
    :year,
    :week,
    :all_cause
]

rename!(df3, cols_to_keep .=> cols_renamed)

# get week and year numbers into vars for easier use later
weeks = df3.week |> sort |> unique
years = df3.year |> sort |> unique

# widen dataframe
wdf = unstack(df3, :year, :all_cause)

# rename year cols for easier access
rename!(wdf, Symbol.(years) .=> Symbol.("year_", years))

# create grouped dataframe to isolate data for entire US
gdf = groupby(wdf, :jurisdiction)

usdf = gdf[("United States",)]

# take out 2021 from analysis since data is incomplete
adj_years = reverse(years[begin:end-1])

# plot all years at once
theme(:dark)
p = Plots.palette(:viridis, 7; rev=true)
plt = plot(
    weeks,
    [usdf[:, Symbol("year_", year)] for year in adj_years],
    # palette=:starrynight,
    palette=p,
    lw=2,
    label=adj_years', # label can take a row vector, so we use the transpose operator `'`
    title="Weekly Deaths from All Causes in the US by Year (2014-2020)",
    xlabel="Week of Year",
    ylabel="Weekly Deaths",
    legend=:bottomleft,
    grid=:y,
    size=(800, 500),
    dpi=200,
    formatter= y -> format(y, autoscale=:metric),
    top_margin=18px,
    left_margin=18px,
    ylim=(0, 100_000)
)

savefig(plt, "plots/plot.png")
