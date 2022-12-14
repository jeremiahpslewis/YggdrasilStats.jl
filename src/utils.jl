using Chain
using TOML
using HTTP

function get_toml_file(repository_name, filename, default_branch)
    @chain "https://raw.githubusercontent.com/$repository_name/$default_branch/$filename?raw=true" begin
        HTTP.get
        String(_.body)
        TOML.parse
    end
end

function get_readme(repository_name, default_branch)
    @chain "https://raw.githubusercontent.com/$repository_name/$default_branch/README.md?raw=true" begin
        HTTP.get
        String(_.body)
    end
end

function extract_readme_metadata(readme_text)
    # if ## sources in text then run next line
    if occursin("## Sources", readme_text)
        source_url = @chain readme_text begin
            replace("\n" => " ")
            replace(
                r".* have been built from these sources:  (.*)  ## Platforms.*" => s"\1"
            )
            split("* ")
            filter(x -> x != "", _)
        end
    else
        source_url = missing
    end

    recipe_url = @chain readme_text begin
        replace("\n" => " ")
        replace(
            r".*(https://github.com/JuliaPackaging/Yggdrasil/blob/[^\)]+build_tarballs\.jl)\).*" =>
                s"\1",
        )
    end
    recipe_url = occursin(r"build_tarballs.jl$", recipe_url) ? recipe_url : missing

    return Dict(:source_url => source_url, :recipe_url => recipe_url)
end

function get_readme_metadata(repository_name::String, default_branch::String)
    try
        readme_text = get_readme(repository_name, default_branch)
        return extract_readme_metadata(readme_text)
    catch
        return Dict()
    end
end

function get_toml_metadata(repository_name::String, default_branch::String)
    try
        project_toml = get_toml_file(repository_name, "Project.toml", default_branch)

        version = project_toml["version"]
        version = replace(version, r"\+[0-9]+" => "")

        # artifacts_toml = get_toml_file(repository_name, "Artifacts.toml")
        # TODO: loop over all platforms to get platform metadata
        # platform_triple = @chain artifacts_toml[binary_name][1] begin
        #    "$(_["arch"])-$(_["os"])-$(_["libc"])"
        # end

        return Dict(:version => version)
    catch
        return Dict()
    end
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
