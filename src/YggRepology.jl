module YggRepology

end

using GitHub
using Base64
using Chain
using TOML

myauth = GitHub.authenticate(ENV["GITHUB_TOKEN"])
binary_repositories = repos("JuliaBinaryWrappers"; auth=myauth)

repository_list = binary_repositories[1]
repository = repository_list[1]

function get_file(repository_name, filename, auth)
    @chain repository_name begin
        file(filename; auth=auth)
        _.content
        base64decode
        String
    end
end

function get_toml_file(repository_name, filename, auth)
    @chain get_file(repository_name, filename, auth) begin
        TOML.parse
    end
end

function get_readme(repository_name, auth)
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
        replace(r".*The originating \[`build_tarballs.jl`\]\((.*)\) script can be found.*" => s"\1")
    end
    return Dict("source_url" => source_url, "recipe_url" => recipe_url)        
end

function get_readme_metadata(repository_name, auth)
    readme_text = get_readme(repository_name, auth)
    return extract_readme_metadata(readme_text)
end

function get_toml_metadata(repository_name, auth)
    project_toml = get_toml_file(repository.full_name, "Project.toml", myauth)
    artifacts_toml = get_toml_file(repository.full_name, "Artifacts.toml", myauth)

    binary_name = @chain project_toml["name"] replace("_jll" => "")
    version = project_toml["version"]

    # TODO: loop over all platforms to get platform metadata
    # platform_triple = @chain artifacts_toml[binary_name][1] begin
    #    "$(_["arch"])-$(_["os"])-$(_["libc"])"
    # end

    return Dict(
        "binary_name" => binary_name,
        "version" => version
    )

end
# Sketch in requirements https://repology.org/docs/requirements


function get_binary_info(repository_name, auth)
    return Dict(
        get_readme_metadata(repository_name, auth)...,
        get_toml_metadata(repository_name, auth)...
    )
end

repository = repository_list[3]
repository_name = repository.full_name

full_binary_metadata = [get_binary_info(repository_name, myauth) for repository_name in repository_list]


