using CSV
using DataFrames

using Plots
using Plots.PlotMeasures
using PlotThemes
using Formatting

# ingest data
file1 = "data/Weekly_Counts_of_Deaths_by_State_and_Select_Causes__2014-2019.csv"
file2 = "data/Weekly_Counts_of_Deaths_by_State_and_Select_Causes__2020-2021.csv"

df1 = CSV.read(file1, DataFrame; normalizenames=true)
df2 = CSV.read(file2, DataFrame; normalizenames=true)

# keep only columns of interest at the moment
cols_to_keep = [
    :Jurisdiction_of_Occurrence,
    :MMWR_Year,
    :MMWR_Week,
    :All_Cause
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
    legend=:top,
    grid=:y,
    size=(800, 500),
    dpi=200,
    formatter=:plain,
    top_margin=18px,
    left_margin=18px,
)

savefig(plt, "plots/plot.png")
