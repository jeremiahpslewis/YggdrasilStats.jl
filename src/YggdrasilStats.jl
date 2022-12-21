module YggdrasilStats

using GitHub
using Chain
using TOML
using DataFrames
using DataFrameMacros
using CSV
using JSON3
using JSONTables
using Dates
using HTTP

include("utils.jl")

function get_binary_info(repository::Repo)
    repository_name = repository.full_name
    default_branch = repository.default_branch

    return Dict(
        get_readme_metadata(repository_name, default_branch)...,
        get_toml_metadata(repository_name, default_branch)...,
        :update_date => repository.updated_at,
        :pushed_at => repository.pushed_at,
        :binary_name => replace(repository.name, "_jll.jl" => ""),
    )
end

function gather_all_binary_info(; maxrepos=nothing)
    auth = GitHub.authenticate(ENV["GITHUB_TOKEN"])
    binary_repositories = repos("JuliaBinaryWrappers"; auth=auth)[1]
    if maxrepos !== nothing
        binary_repositories = binary_repositories[1:maxrepos]
    end

    full_binary_metadata = [
        get_binary_info(repository) for repository in binary_repositories
    ]
    return full_binary_metadata
end

function export_all_binary_info(; maxrepos=nothing)
    full_binary_metadata = gather_all_binary_info(; maxrepos=maxrepos)

    df = DataFrame([i for i in full_binary_metadata if haskey(i, :version)])

    # Full dataset
    df = @chain df begin
        @transform(:patch_directories = @passmissing get_patch_directories(:source_url))
        @transform(:source_url = @passmissing drop_url_from_list(:source_url))
        @transform(:update_date = :update_date, :pushed_at = :pushed_at,)
        @transform(:error = !(:source_url isa String))
    end

    df_good = @chain df begin
        @subset(:error != true)
        @select(
            :binary_name,
            :version,
            :source_url,
            :recipe_url,
            :update_date,
            :patch_directories
        )
    end

    open("full_binary_metadata.json", "w") do f
        JSON3.pretty(f, JSONTables.arraytable(df_good))
    end

    return df
end

get_version_vars(julia_string) = [e.args for e in Meta.parseall(julia_string).args if hasproperty(e, :args) && occursin(r"version|_ver", string(e.args[1]))]

function get_version_vars_from_build_tarballs(url)
    a = @chain url begin
        HTTP.get(; query=Dict("raw" => "true"))
        _.body
        String
        get_version_vars
    end
end

end # module
