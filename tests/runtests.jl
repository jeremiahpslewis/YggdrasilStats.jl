using Test

@test get_toml_file("bmon_jll.jl", "Project.toml")["version"] >= "3" 

@test get_readme("bmon_jll.jl") isa String
