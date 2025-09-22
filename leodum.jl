include("extraction_of_path_arthur.jl")
include("felou.jl")
include("juju.jl")
include("parser.jl")

# Importation des données JSON (parse)
import Pkg
Pkg.add("JSON")
using JSON
donnees = JSON.parsefile("data.json")
collection = donnees["collection"]
questions = donnees["questions"]

df = build_species_matrix(collection)
df_clean = clean_species_matrix(df)
df_encoded, mapping = encode_characteristics(df_clean)

println("Première ligne encodée :")
println(df_encoded[1, :])

println("\nCorrespondance :")
for (i, feat) in sort(collect(mapping))
    println("caractéristique $i = $(feat)")
end

# Test de compréhension du jeu de données
#println(donnees)
println(donnees["questions"][1]["answers"][1]["title_a"])

print(donnees["collection"][24]["latin"])

# Fonction de vérification d'appartenance d'une caractéristique pour une espèce
function verif_species_has_caract(df_caract_species::DataFrame, 
    name_species::String, list_caract::Vector{String})
    
    # On trouve la ligne correspondant à l'espèce en cherchant le nom de celle ci dans la colonne Species
    # Findfirst donne l'indice de la première ligne possédant "name_species"
    row_index = findfirst(==("$(name_species)"), df_caract_species[:, :Species])

    # Erreur si l'espèce ne fait pas partie de notre base de données 
    if row_index === nothing
        error("Espèce $name_species non trouvée dans le DataFrame")
    end

    # On vérifie ensuite que l'espèce possède la liste des carctéristiques demandés
    for c in list_caract

        # Gestion de l'erreur où la caractéristiques n'existe pas dans nos données (aucune info dessus donc)
        if !haskey(df, c)
            error("Caractéristique $c n'existe pas dans le DataFrame")
        end

        # Si l'espèce ne possède pas la caracteristique (proba=0 de l'avoir) alors on renvoie false 
        if df[row_idx, c] == 0
            println("$(name_species) ne possède pas la caractéristique : $(c)")
            return false
        end
    end

    # Si toutes les caractéristiques demandées sont bien présentes sur l'espèce alors on valide le tout 
    return true
end



