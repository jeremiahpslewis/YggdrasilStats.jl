module YggRepology

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

function get_patch_directories(source_url)
    patch_directories = source_url[occursin.("files in directory", source_url)]
    patch_directories =
        replace.(patch_directories, r".*(https://github.com/.*/bundled).*" => s"\1")

    if length(patch_directories) == 1
        return patch_directories[1]
    elseif length(patch_directories) == 0
        return missing
    else
        return patch_directories
    end
end

function export_all_binary_info()
    full_binary_metadata = gather_all_binary_info()

    df = DataFrame([i for i in full_binary_metadata if haskey(i, :version)])

    # Full dataset
    df = @chain df begin
        @transform(
            :source_url = drop_url_from_list(:source_url),
            :patch_directories = get_patch_directories(:source_url),
            :update_date = :update_date,
            :pushed_at = :pushed_at,
        )
        @transform(:error = !(:source_url isa String) | (:update_date < Date("2021-01-01")))
    end

    df_good = @chain df begin
        @subset(:error != true)
        @select(
            :binary_name, :version, :source_url, :recipe_url, :update_date, :patch_directories
        )
    end

    open("full_binary_metadata.json", "w") do f
        JSONTables.arraytable(f, df_good)
    end

    return df
end

end # module
