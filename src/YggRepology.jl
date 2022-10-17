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

repository.full_name
binary_name = replace(repository.name, "_jll.jl" => "")
binary_repositories[1][1].name

# reformat to use chain base64decode(file(repository.full_name, "Project.toml"; auth=myauth).content)

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


project_toml = get_toml_file(repository.full_name, "Project.toml", myauth)
artifacts_toml = get_toml_file(repository.full_name, "Artifacts.toml", myauth)



readme_text = get_readme(repository.full_name, myauth)


# Sketch in requirements https://repology.org/docs/requirements
# Metadata

binary_name = @chain project_toml["name"] replace("_jll" => "")
version = project_toml["version"]
# TODO: clean this up...
source_url = @chain readme_text begin
    replace("\n" => " ") 
    replace(r".* have been built from these sources:  (.*)  ## Platforms.*" => s"\1")
end
recipe_url = @chain readme_text begin
    replace("\n" => " ") 
    replace(r".*The originating \[`build_tarballs.jl`\]\((.*)\) script can be found.*" => s"\1")
end

# TODO: loop over all platforms
# platform_triple = @chain artifacts_toml[binary_name][1] begin
#    "$(_["arch"])-$(_["os"])-$(_["libc"])"
# end

