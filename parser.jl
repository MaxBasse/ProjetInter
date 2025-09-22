using JSON
using PrettyPrint

data = JSON.parsefile("data.json")


function get_characteristics(species_name, data)
    species = filter(x -> x["latin"] == species_name, data["collection"])[1]
    isempty(species) && return []

    chars = String[]
    for choice in species["choices"]
        for opt in choice["options"]
            label, score, _ = opt

            score > 0.0 && push!(chars, label)
            
        end
    end
    return chars
end

function get_characteristics2(species_name, data)
    species = filter(x -> x["latin"] == species_name, data["collection"])[1]
    isempty(species) && return []

    carac = Dict{String, Vector{String}}()

    for choice in species["choices"]
        question = choice["id_question"]
        for opt in choice["options"]
            label, score, _ = opt
            if score > 0.0 
                if haskey(carac, question)
                    push!(carac[question], label)
                else 
                    carac[question] = [label]
                end
            end      
        end
    end
    return carac
end



println("Viola tricolor : ", get_characteristics("Viola tricolor", data))
println()
pprint(get_characteristics2("Viola tricolor", data))

function build_index_s_c(data)
    index = Dict{String, Dict{String, Vector{String}}}()
    for species in data["collection"]
        spname = species["latin"]

        for choice in species["choices"]
            question = choice["id_question"]
            for opt in choice["options"]
                label, score, _ = opt
                if score > 0.0 
                    if !haskey(index, question)
                        index[question] = Dict{String, Vector{String}}()
                    end
                    if haskey(index[question], label)
                        push!(index[question][label], spname)
                    else
                        index[question][label] = [spname]
                    end
                end      
            end
        end
    end
    return index
end

function build_index_c_s(data)
    index = Dict{String, Dict{String, Vector{String}}}()
    for species in data["collection"]
        spname = species["latin"]

        for choice in species["choices"]
            question = choice["id_question"]
            for opt in choice["options"]
                label, score, _ = opt
                if score > 0.0 
                    if !haskey(index, question)
                        index[question] = Dict{String, Vector{String}}()
                    end
                    if haskey(index[question], label)
                        push!(index[question][label], spname)
                    else
                        index[question][label] = [spname]
                    end
                end      
            end
        end
    end
    return index
end

index = build_index(data)

pprint(index)

function species_with(char, index)
    return get(index, char, String[])
end

#println(species_with("Herbacées", index))

function species_with_all(chars, index)
    sets = [Set(species_with(c, index)) for c in chars]
    return reduce(intersect, sets)
end

#println(species_with_all(["Herbacées", "feuilles non découpées"], index))