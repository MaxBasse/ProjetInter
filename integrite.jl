using JSON
using DataFrames
donnees = JSON.parsefile("data.json")
questions=donnees["questions"]


function collect_species(node)
    species = Set{String}()
    if haskey(node, "species")
        union!(species, node["species"])
    end

    if haskey(node, "options")
        for opt in node["options"]
            if haskey(opt, "species")
                union!(species, opt["species"])
            end
            if haskey(opt, "subquestions")
                union!(species, collect_species(opt["subquestions"]))
            end
        end
    end
    return species
end

function check_tree_integrity(node; parent_species=Set{String}())
    errors = String[]

    # Collecte des espèces à ce niveau
    local_species = collect_species(node)

    # Vérifie cohérence avec le parent (si applicable)
    if !isempty(parent_species)
        missing = setdiff(parent_species, local_species)
        if !isempty(missing)
            push!(errors, "⚠️ Espèces perdues ici: $(collect(missing))")
        end
    end

    # Vérifie duplicatas dans les options
    if haskey(node, "options")
        seen = Set{String}()
        for opt in node["options"]
            opt_species = collect_species(opt)
            dup = intersect(seen, opt_species)
            if !isempty(dup)
                push!(errors, "⚠️ Espèces dupliquées entre options: $(collect(dup))")
            end
            union!(seen, opt_species)

            # Vérifie récursivement les sous-questions
            if haskey(opt, "subquestions")
                append!(errors, check_tree_integrity(opt["subquestions"]; parent_species=opt_species))
            end
        end
    end

    return errors
end

print(collect_species(questions))