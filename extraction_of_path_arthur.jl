
import Pkg
Pkg.add("JSON")
using JSON
donnees = JSON.parsefile("data.json")

#println(donnees)
#println(donnees["questions"][1]["title_q"])
#println(donnees["questions"][1]["answers"][1]["title_a"])
#println(donnees["questions"][2]["title_q"])

function extraction_of_path(data;actual_path=Vector{Pair{String,String}}())
    paths = Dict{String, Any}[]

    # on stocke tous les resultats dans un vecteur de dictionnaires
    # la clé du dictionnaire est le nom de l'espece et la valeur est ses caractéristiques
    # caractéristiques = le chemin emprunté pour tomber sur cette espece 
    if haskey(data, "questions")
    # la clé de data doit bien exister et etre "questions
            for q in data["questions"]
                question = q["title_q"]
                for ans in q["answers"]
                    new_path = copy(actual_path)
                    push!(new_path, question => ans["title_a"])
                    # copie pour éviter la modification puis ajout de la question et de la réponse au chemin actuel
                    if haskey(ans, "unlock_questions") && !isempty(ans["unlock_questions"])
                        for sub_q in ans["unlock_questions"]
                            sub_data = Dict("questions" => [sub_q])
                            # nouveau dictionnaire pour appeler la fonction récursivement
                            append!(paths, extraction_of_path(sub_data; actual_path=new_path))
                        end
                    else
                    # On fabrique un dictionnaire au lieu de pousser directement new_path
                    push!(paths, Dict(
                        "species" => ans["title_a"],          # on prend le dernier answer comme espèce
                        "characteristics" => new_path         # tout le chemin parcouru
                    ))
                end
                end
            end
        end

    return paths
end

vect=extraction_of_path(donnees)
for v in vect
    println("Espèce : ", v["species"])
    println("Caractéristiques : ", v["characteristics"])
end