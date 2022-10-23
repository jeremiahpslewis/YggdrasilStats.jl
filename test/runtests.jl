using Test
using YggRepology

@testset "YggRepology utils" begin
    @test YggRepology.get_toml_file("JuliaBinaryWrappers/DuckDB_jll.jl", "Project.toml", "main")["version"] >= "0.2"

    @test YggRepology.get_readme("JuliaBinaryWrappers/DuckDB_jll.jl", "main") isa String

    @test occursin(
        "git repository: ",
        YggRepology.extract_readme_metadata(YggRepology.get_readme("JuliaBinaryWrappers/DuckDB_jll.jl", "main"))[:source_url][1],
    )

    @test occursin(
        "git repository: ",
        YggRepology.get_readme_metadata("JuliaBinaryWrappers/DuckDB_jll.jl", "main")[:source_url][1],
    )
    
    @test YggRepology.get_toml_metadata("JuliaBinaryWrappers/DuckDB_jll.jl", "main")[:version] >= "0.2.5"

    # drop_url_from_list([""]
end


    # myauth = GitHub.authenticate(ENV["GITHUB_TOKEN"])
    # binary_repositories = repos("JuliaBinaryWrappers"; auth=myauth)

    # repository_list = binary_repositories[1]
    # repository = repository_list[1]

    # repository_list_ = repository_list[101:200]
    # repository = repository_list[1]
    # repository_name = repository.full_name

    # get_binary_info(repository)
    # full_binary_metadata = [
    #     get_binary_info(repository) for
    #     repository in repository_list if repository.updated_at > Date("2021-01-01")
    # ]

    # export_all_binary_info()
    # get_all_binary_info()
