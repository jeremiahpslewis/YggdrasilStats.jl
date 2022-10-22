module YggRepology

end

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

function get_file(repository_name, filename, auth::GitHub.OAuth2)
    @chain repository_name begin
        file(filename; auth=auth)
        _.content
        base64decode
        String
    end
end

function get_toml_file(repository_name, filename, auth::GitHub.OAuth2)
    @chain get_file(repository_name, filename, auth) begin
        TOML.parse
    end
end

function get_readme(repository_name, auth::GitHub.OAuth2)
    @chain repository_name begin
        readme(; auth=auth)
        _.content
        base64decode
        String
    end
end

""

function extract_readme_metadata(readme_text)
    source_url = @chain readme_text begin
        replace("\n" => " ")
        replace(r".* have been built from these sources:  (.*)  ## Platforms.*" => s"\1")
        split("* ")
        filter(x -> x != "", _)
    end
    recipe_url = @chain readme_text begin
        replace("\n" => " ")
        replace(r".*(https://github.com/JuliaPackaging/Yggdrasil/blob/[^\)]+build_tarballs\.jl)\).*" => s"\1")
    end
    return Dict(:source_url => source_url, :recipe_url => recipe_url)
end

function get_readme_metadata(repository_name::String, auth::GitHub.OAuth2)
    try
        readme_text = get_readme(repository_name, auth)
        return extract_readme_metadata(readme_text)
    catch
        return Dict()
    end
end

function get_toml_metadata(repository_name::String, auth::GitHub.OAuth2)
    try
        project_toml = get_toml_file(repository_name, "Project.toml", auth)
        artifacts_toml = get_toml_file(repository_name, "Artifacts.toml", auth)

        binary_name = @chain project_toml["name"] replace("_jll" => "")
        version = project_toml["version"]

        # TODO: loop over all platforms to get platform metadata
        # platform_triple = @chain artifacts_toml[binary_name][1] begin
        #    "$(_["arch"])-$(_["os"])-$(_["libc"])"
        # end

        return Dict(:binary_name => binary_name, :version => version)
    catch
        return Dict()
    end
end

# Sketch in requirements https://repology.org/docs/requirements

function get_binary_info(repository::Repo, auth::GitHub.OAuth2)
    repository_name = repository.full_name
    return Dict(
        get_readme_metadata(repository_name, auth)...,
        get_toml_metadata(repository_name, auth)...,
        :update_date => repository.updated_at,
        :pushed_at => repository.pushed_at,
    )
end

function gather_all_binary_info()
    auth = GitHub.authenticate(ENV["GITHUB_TOKEN"])
    binary_repositories = repos("JuliaBinaryWrappers"; auth=auth)
    full_binary_metadata = [
        get_binary_info(repository, auth) for repository in binary_repositories[1]
    ]
    return full_binary_metadata
end

function drop_url_from_list(x)
    x = replace.(x, r" \(revision: .*" => "")
    x = replace.(x, r" \(SHA256 checksum.*" => "")
    x = replace.(x, r".*(https?://.*)" => s"\1")

    if length(x) != 1
        return x
    else
        return x[1]
    end
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

repository_list_ = repository_list[1:100]
repository = repository_list[1]
repository_name = repository.full_name

get_binary_info(repository, myauth)

full_binary_metadata = [
    get_binary_info(repository, myauth) for repository in repository_list_
]

df = DataFrame(full_binary_metadata)

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

# CSV.write("full_binary_metadata.csv", df)

df_good = @chain df begin
    @subset(:error != true)
    # @select(:binary_name, :version, :source_url, :recipe_url)
end

open("full_binary_metadata.json", "w") do f
    JSONTables.arraytable(f, df_good)
end

