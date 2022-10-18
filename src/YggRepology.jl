module YggRepology

end

using GitHub
using Base64
using Chain
using TOML
using DataFrames
using DataFrameMacros

function get_file(repository_name, filename, auth::Github.OAuth2)
    @chain repository_name begin
        file(filename; auth=auth)
        _.content
        base64decode
        String
    end
end

function get_toml_file(repository_name, filename, auth::Github.OAuth2)
    @chain get_file(repository_name, filename, auth) begin
        TOML.parse
    end
end

function get_readme(repository_name, auth::Github.OAuth2)
    @chain repository_name begin
        readme(; auth=auth)
        _.content
        base64decode
        String
    end
end

function extract_readme_metadata(readme_text)
    source_url = @chain readme_text begin
        replace("\n" => " ")
        replace(r".* have been built from these sources:  (.*)  ## Platforms.*" => s"\1")
        split("* ")
        filter(x -> x != "", _)
    end
    recipe_url = @chain readme_text begin
        replace("\n" => " ")
        replace(r".*(https://github.com/JuliaPackaging/Yggdrasil/blob/.*.jl\)).*" => s"\1")
    end
    return Dict("source_url" => source_url, "recipe_url" => recipe_url)
end

function get_readme_metadata(repository_name::String, auth::Github.OAuth2)
    try
        readme_text = get_readme(repository_name, auth)
        return extract_readme_metadata(readme_text)
    catch
        return Dict()
    end
end

function get_toml_metadata(repository_name::String, auth::Github.OAuth2)
    try
        project_toml = get_toml_file(repository_name, "Project.toml", myauth)
        artifacts_toml = get_toml_file(repository_name, "Artifacts.toml", myauth)

        binary_name = @chain project_toml["name"] replace("_jll" => "")
        version = project_toml["version"]
    
        # TODO: loop over all platforms to get platform metadata
        # platform_triple = @chain artifacts_toml[binary_name][1] begin
        #    "$(_["arch"])-$(_["os"])-$(_["libc"])"
        # end
    
        return Dict("binary_name" => binary_name, "version" => version)
    catch
        return Dict()
    end

end
# Sketch in requirements https://repology.org/docs/requirements

function get_binary_info(repository::Repo, auth::Github.OAuth2)
    repository_name = repository.full_name
    return Dict(
        get_readme_metadata(repository_name, auth)...,
        get_toml_metadata(repository_name, auth)...,
        :update_date => repository.updated_at
    )
end

function gather_all_binary_info()
    myauth = GitHub.authenticate(ENV["GITHUB_TOKEN"])
    binary_repositories = repos("JuliaBinaryWrappers"; auth=myauth)
    full_binary_metadata = [
        get_binary_info(repository_name, myauth) for
        repository_name in binary_repositories[1]
    ]
    return full_binary_metadata
end

drop_url_from_list(x) = length(x) != 1 ? x : replace(x[1], r".*(https?://.*)" => s"\1")

myauth = GitHub.authenticate(ENV["GITHUB_TOKEN"])
binary_repositories = repos("JuliaBinaryWrappers"; auth=myauth)

repository_list = binary_repositories[1]
repository = repository_list[1]

repository_list_ = repository_list[1:100]
repository = repository_list[1]
repository_name = repository.full_name

get_binary_info(repository_name, myauth)

full_binary_metadata = [
    get_binary_info(repository_name, myauth) for repository_name in repository_list_
]

df = DataFrame(full_binary_metadata)



@chain df begin
    @transform :source_url = drop_url_from_list(:source_url)
    @subset !(:source_url isa String)
end
