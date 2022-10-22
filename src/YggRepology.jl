module YggRepology

using GitHub
using Base64
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
    return Dict(
        get_readme_metadata(repository_name)...,
        get_toml_metadata(repository_name)...,
        :update_date => repository.updated_at,
        :pushed_at => repository.pushed_at,
        :binary_name => replace(repository.name, "_jll.jl" => ""),
    )
end

function gather_all_binary_info()
    auth = GitHub.authenticate(ENV["GITHUB_TOKEN"])
    binary_repositories = repos("JuliaBinaryWrappers"; auth=auth)
    full_binary_metadata = [
        get_binary_info(repository) for repository in binary_repositories[1]
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

myauth = GitHub.authenticate(ENV["GITHUB_TOKEN"])
binary_repositories = repos("JuliaBinaryWrappers"; auth=myauth)

repository_list = binary_repositories[1]
repository = repository_list[1]

repository_list_ = repository_list[101:200]
repository = repository_list[1]
repository_name = repository.full_name

get_binary_info(repository)

full_binary_metadata = [
    get_binary_info(repository) for repository in repository_list if repository.updated_at > Date("2021-01-01")
]

df = DataFrame([i for i in full_binary_metadata if haskey(i, :version)])

# Full dataset
df = @chain df begin
    @transform(
        :source_url = drop_url_from_list(:source_url),
        :patch_directories = get_patch_directories(:source_url),
        :update_date = :update_date,
        :pushed_at = :pushed_at,
    )
    @transform(
        :error =
            !(:source_url isa String) |
            (:update_date < Date("2021-01-01"))
    )
end

df_good = @chain df begin
    @subset(:error != true)
    @select(:binary_name, :version, :source_url, :recipe_url, :update_date, :patch_directories)
end

open("full_binary_metadata.json", "w") do f
    JSONTables.arraytable(f, df_good)
end


end
