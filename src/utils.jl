using Chain
using TOML
using HTTP

function get_toml_file(repository_name, filename)
    @chain "https://raw.githubusercontent.com/$repository_name/master/$filename?raw=true" begin
        HTTP.get
        String(_.body)
        TOML.parse
    end
end

function get_readme(repository_name)
    @chain "https://raw.githubusercontent.com/$repository_name/master/README.md?raw=true" begin
        HTTP.get
        String(_.body)
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
        replace(
            r".*(https://github.com/JuliaPackaging/Yggdrasil/blob/[^\)]+build_tarballs\.jl)\).*" =>
                s"\1",
        )
    end
    return Dict(:source_url => source_url, :recipe_url => recipe_url)
end

function get_readme_metadata(repository_name::String)
    try
        readme_text = get_readme(repository_name)
        return extract_readme_metadata(readme_text)
    catch
        return Dict()
    end
end

function get_toml_metadata(repository_name::String)
    try
        project_toml = get_toml_file(repository_name, "Project.toml")

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
