
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
"""
vect=extraction_of_path(donnees)
for v in vect
    println("Espèce : ", v["species"])
    println("Caractéristiques : ", v["characteristics"])
end
"""

using DataFrames

"""
Parcourt récursivement les choix/questions pour une espèce
et retourne un Dict(question::réponse => score)
"""
function extract_characteristics(choices)
    d = Dict{String, Float64}()

    for choice in choices
        # recupere les caractéristiques de la question
        q = String(choice["id_question"])
        for opt in choice["options"]
            answer = String(opt[1])
            score  = Float64(opt[2])

            key = q * "::" * answer
            d[key] = score

            # Sous-questions éventuelles
            subqs = opt[3]
            if !isempty(subqs)
                subdict = extract_characteristics(subqs)
                # recursivité pour faire de meme avec les questions imbriquées
                merge!(d, subdict)
            end
        end
    end

    return d
end

"""
Construit une matrice espèce × caractéristiques
"""


function build_species_matrix(collection)
    rows = []
    for species in collection
        # pour toutes les especes on récupere les caractéristiques dans un dictionnaire cle valeur 
        # ou la clé est le nom de la caractéristique et la valeur le score (la probabilité que l'espèce ait cette caractéristique)
        # on ajoute aussi le nom de l'espèce en valeur de la clé espece
        latin = String(species["latin"])
        d = Dict{String,Any}()
        d["espece"] = latin
        merge!(d, extract_characteristics(species["choices"]))
        push!(rows, d)
    end

    # sur toutes les colonnes, trouver toutes les clés possibles
    # les dico n'ont actuellement pas tous les memes cle 
    # on crée donc une liste de toutes les cles que l'on va ajouter aux dico
    all_keys = Set{String}()
    for r in rows
        union!(all_keys, keys(r))
    end
    all_keys = collect(all_keys)

    # Complete les dicos avec les cles manquantes
    complete_rows = []
    for r in rows
        d_complete = Dict{String,Any}()
        for k in all_keys
            d_complete[k] = get(r, k, missing)
        end
        push!(complete_rows, d_complete)
    end

    df = DataFrame(complete_rows)

    # Remplacer les missing par 0.0 sauf pour "espece" (gestion d'une erreur)
    # a voir ce qu'on fait despece qui n'est pas une caracterisituque mais on en a besoin pour savoir ce qu'on traite
    
    for c in names(df)
        if c != "espece"
            df[!, c] = coalesce.(df[!, c], 0.0)
        end
    end

    return df
end


function clean_species_matrix(df::DataFrame)
    #en gros nettoyer les noms des colonnes pour meilleure lisiibilité (mais ca ne sera meme pas suffisant)
    rename!(df, "espece" => :Species)

    newnames = Symbol[]
    for name in names(df)
        if name == :Species
            push!(newnames, :Species)
        else
            s = String(name)

            # Séparer question et modalité
            parts = split(s, "::")
            question = replace(parts[1], r"[^A-Za-z0-9 ]" => "")  # nettoyer caractères spéciaux
            question = lowercase(strip(question))
            question = replace(question, " " => "_")

            if length(parts) > 1
                modality = replace(parts[2], r"[^A-Za-z0-9 ]" => "")
                modality = lowercase(strip(modality))
                modality = replace(modality, " " => "_")
                clean = "$(question)_$(modality)"
            else
                clean = question
            end

            push!(newnames, Symbol(clean))
        end
    end

    rename!(df, Dict(names(df) .=> newnames))

    # Convertir en Int si binaire
    for c in names(df)
        if c != :Species && eltype(df[!, c]) <: Float64
            vals = unique(df[!, c])
            if all(x -> x in (0.0, 1.0), vals)
                df[!, c] = Int.(df[!, c])
            end
        end
    end
    

    df = select(df, :species, Not(:species))

    col=df[1,:];
    row=df[:,1];
    df=df[:,2:end];
    return df, row, col
end






# utilisation

collection = donnees["collection"];

df = build_species_matrix(collection);
df_clean,col,row = clean_species_matrix(df);
print(col);
print(row);



