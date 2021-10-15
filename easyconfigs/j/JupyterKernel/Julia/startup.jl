userhome = ENV["HOME"]
usershell = ENV["SHELL"]
envregex = r"((^export JULIA)|(^JULIA))_(.*)=(.*)"
shellregex = r"(zsh$|bash$)"

matchshell = match(shellregex, usershell)
rcfile = "."*matchshell[1]*"rc"
shellrcfile = string(userhome)*"/"*string(rcfile)

#=
reading the shells rc file in $HOME and configure the environment with all variables set in the rc file
=#
open(shellrcfile) do f
    for i in eachline(f)
        matchregex = match(envregex, i)
        if matchregex !== nothing
            if matchregex[4] == "DEPOT_PATH"
                pushfirst!(DEPOT_PATH, string(matchregex[5]))
                ENV["JULIA_DEPOT_PATH"] = string(matchregex[5])
            end
        end
    end
end

#=
set DEPOT_PATH to users first slurm account $PC2FS directory if the DEPOT_PATH is not set explicity in the shells rc file
=#
get_groups_cmd = "/usr/bin/groups"
groups_regex = r"(HPC-[A-Z]{3}-.*|hpc-[a-z]{3}-.*|pc2-mitarbeiter|HPC-SNF)"
if length(DEPOT_PATH) <= 1
    groups = read(`$get_groups_cmd`, String)
    groups = replace(string(groups), " " => "\n")
    fgroups = []
    for i in eachline(IOBuffer(groups))
        matchregex = match(groups_regex, i)
        if matchregex !== nothing
            push!(fgroups, matchregex[1])
        end
    end

    if length(fgroups) >= 1
        username = ENV["USER"]
        user_depot_path = "/scratch/"*string(fgroups[1])*"/"*string(username)*"/.julia/"
        pushfirst!(DEPOT_PATH, string(user_depot_path))
        ENV["JULIA_DEPOT_PATH"] = string(user_depot_path)
    end
end
