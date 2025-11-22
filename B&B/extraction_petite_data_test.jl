using JSON, DataFrames, CSV

# --- Charger les données JSON ---
fichier = raw"C:\Users\leopa\OneDrive\Documents\Perso\Travail INSA\MA\S7\Projet interdisciplinaire\ProjetInter\B&B\petite_data_test.json"
data = JSON.parsefile(fichier)

# Fonction pour nettoyer les noms de caractéristiques
function clean_names(df::DataFrame)
    rename!(df, "espece" => :Species)
    newnames = Symbol[]
    for name in names(df)
        if name == :Species
            push!(newnames, :Species)
        else
            s = String(name)
            parts = split(s, "::")
            question = lowercase(strip(parts[1]))
            question = replace(question, " " => "_")
            if length(parts) > 1
                modality = lowercase(strip(parts[2]))
                modality = replace(modality, " " => "_")
                push!(newnames, Symbol("$(question)_$(modality)"))
            else
                push!(newnames, Symbol(question))
            end
        end
    end
    rename!(df, Dict(names(df) .=> newnames))
    return df
end

# Fonction pour extraire les caractéristiques et construire la matrice
function extract_characteristics(choices)
    d = Dict{String, Float64}()
    for choice in choices
        q = String(choice["id_question"])
        for opt in choice["options"]
            key = q * "::" * String(opt[1])
            d[key] = Float64(opt[2])
            if !isempty(opt[3])
                subdict = extract_characteristics(opt[3])
                merge!(d, subdict)
            end
        end
    end
    return d
end

function build_species_matrix(collection)
    rows = []
    for species in collection
        latin = String(species["latin"])
        # Dict{String, Any} pour accepter à la fois le nom de l'espèce et les Float64
        d = Dict{String, Any}("espece" => latin)
        merge!(d, extract_characteristics(species["choices"]))
        push!(rows, d)
    end

    # Trouver toutes les clés possibles
    all_keys = Set{String}()
    for r in rows
        union!(all_keys, keys(r))
    end
    all_keys = collect(all_keys)

    # Compléter chaque dictionnaire avec les clés manquantes
    complete_rows = []
    for r in rows
        d_complete = Dict{String, Any}()
        for k in all_keys
            d_complete[k] = get(r, k, 0.0)
        end
        push!(complete_rows, d_complete)
    end

    return DataFrame(complete_rows)
end


# Construire la DataFrame complète
df = build_species_matrix(donnees["collection"])
df_clean = clean_names(df)

# Extraire species_col et df_matrix
species_col = df_clean[!, :species]
df_matrix = select(df_clean, Not(:species))  # uniquement les valeurs numériques
characteristics_row = names(df_matrix)

# Export CSV
CSV.write("species_column_petite.csv", DataFrame(Species = species_col))
CSV.write("species_matrix_petite.csv", df_matrix; writeheader=false)
CSV.write("characteristics_row_petite.csv", DataFrame(Characteristic = characteristics_row))

