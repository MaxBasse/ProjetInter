include("extraction_of_path_arthur.jl")

#OBSOLETE FILE, kept for reference only

# Importation des données JSON initiales (parse)
import Pkg
Pkg.add("JSON")
using JSON
donnees = JSON.parsefile("data.json")
collection = donnees["collection"]
questions = donnees["questions"]


# Je construis la matrice espèces/caractéristique avec les fonctions de Arthur pour l'utiliser dans mes fonctions
df = build_species_matrix(collection)
df_clean = clean_species_matrix(df)
df_encoded, mapping = encode_characteristics(df_clean)


# ANCIENNE VERSION DES FONCTIONS (NOUVELLES VERSIONS LIGNE 112) :


"""
verif_species_has_caract_old : Fonction de vérification d'appartenance d'une caractéristique pour une espèce

Arguments :
- df_caract_species (DataFrame) : matrice des espèces (lignes) et de leurs caracteristiques (colonnes) avec leur proba
- name_species (String) : nom de l'espèce dont on veut vérifier la possession ou non de caractéristiques données
- list_caract (Vector{String}) : liste de caractéristiques dont on veut vérifier l'existence pour une espèce donnée

Sortie : Retourne un bouléen (True/False) concernant l'existence de la liste des caractéristiques pour l'espèce donnée 
"""
function verif_species_has_caract_old(df_caract_species::DataFrame,  
    name_species::String, list_caract::Vector{String})
    
    # On trouve la ligne correspondant à l'espèce en cherchant le nom de celle ci dans la colonne species
    # Findfirst donne l'indice de la première ligne possédant "name_species"
    row_index = findfirst(==("$(name_species)"), df_caract_species[:, :species])

    # Erreur si l'espèce ne fait pas partie de notre base de données 
    if row_index === nothing
        error("Espèce $name_species non trouvée dans le DataFrame")
    end

    # On vérifie ensuite que l'espèce possède la liste des carctéristiques demandés
    for c in list_caract

        # Gestion de l'erreur où la caractéristiques n'existe pas dans nos données (aucune info dessus donc)
        if !(c in names(df_caract_species))
            error("Caractéristique $c n'existe pas dans le DataFrame")
        end

        # Si l'espèce ne possède pas la caracteristique (proba=0 de l'avoir) alors on renvoie false 
        if df[row_index, c] == 0
            println("$(name_species) ne possède pas la caractéristique : $(c)")
            return false
        end
    end

    # Si toutes les caractéristiques demandées sont bien présentes sur l'espèce alors on valide le tout 
    return true
end

"""
# Différents tests pour la construction de la fonction : verif_species_has_caract

# test 1 sur la caractéristique 3 = combien_de_ptales_voyezvous_5_ou_10 (vraie avec proba 1)
println(verif_species_has_caract(df_clean, "Viola tricolor", ["combien_de_ptales_voyezvous_5_ou_10"]))

# test 2 avec la caractéristique 2 = la_corolle_ensemble_des_ptales_est_papilionace_ou_fumarie (Faux)
println(verif_species_has_caract(df_clean, "Viola tricolor", ["combien_de_ptales_voyezvous_5_ou_10", "la_corolle_ensemble_des_ptales_est_papilionace_ou_fumarie"]))

#test 3 sur la caractéristique 100 = quelle_forme_a_la_section_de_la_tige_arrondie (vrai avec proba 0.5)
println(verif_species_has_caract(df_clean, "Viola tricolor", ["combien_de_ptales_voyezvous_5_ou_10", "quelle_forme_a_la_section_de_la_tige_arrondie"]))
"""




# Je code maintenant la fonction qui servira à mettre à jour la liste des espèces restantes après chaque branche 
# emprunté, c'est à dire après chaque réponse donnée.

"""
remaining_species_update_old : Fonction de mise à jour de la liste des espèces restantes pouvant être l'espèce à 
identifié d'après les réponses de toutes les précédentes questions

Arguments :
- df_caract_species (DataFrame) : matrice des espèces (lignes) et de leurs caracteristiques (colonnes) 
avec leur proba
- remaining_species (Vector{String}) : liste des espèces restantes avant la réponse donnée
- answer_carac (String) : réponse à la question posée (et donc une caractéristique donnée)

Sortie : Retourne la liste des espèces restantes qui répondent à l'ensemble des critères obtenues 
jusque cet instant
"""
function remaining_species_update_old(df_caract_species::DataFrame, 
    remaining_species::Vector{String}, answer_carac::String)

    # On créé notre nouvelle liste vide d'espèces restantes qu'on va remplir (vecteur de string)
    new_remaining_species = String[] 
    
    # pour toutes les espèces restantes, on vérifie si elles sont en accord avec la réponse à la dernière 
    # question (nouvelle caractéristique). Si c'est le cas, on ajoute l'espèce à notre nouvelle liste.
    for sp in remaining_species
        if verif_species_has_caract_old(df_caract_species, sp, answer_carac)
            push!(new_remaining_species, sp)
        end
    end

    return new_remaining_species
end

# NOUVELLE VERSION ADAPTEE AUX FORMATS DES DONNEES :

"""
verif_species_has_caract : Fonction de vérification d'appartenance d'une caractéristique pour une espèce

Arguments :
- df_caract_species (DataFrame) : matrice des espèces (lignes) et de leurs caracteristiques (colonnes) avec leur proba
- species_id (Int) : identifiant (index de ligne) de l’espèce à vérifier
- caract_ids (Vector{Int}) : identifiants (index de colonnes) des caractéristiques à tester

Sortie :
- Booléen (true si l’espèce possède toutes les caractéristiques demandées, false sinon)
"""
function verif_species_has_caract(df_caract_species::DataFrame,
                                  species_id::Int,
                                  caract_ids::Vector{Int})

    # vérifs d'erreurs d'identifiants
    if species_id > nrow(df_caract_species)
        error("Identifiant d'espèce $(species_id) hors limites du DataFrame.")
    end

    if any(x -> x > ncol(df_caract_species), caract_ids)
        error("Un ou plusieurs identifiants de caractéristiques sont hors limites du DataFrame.")
    end

    # On parcourt chaque caractéristique demandée pour vérifier si l'espèce la possède
    for c_id in caract_ids
        prob = df_caract_species[species_id, c_id]

        # Si proba = 0, l'espèce ne possède pas cette caractéristique
        if prob == 0
            return false
        end
    end

    # Si toutes les caractéristiques sont présentes (proba > 0)
    return true
end



"""
remaining_species_update : Fonction de mise à jour de la liste des espèces restantes pouvant être l'espèce à 
identifié d'après les réponses de toutes les précédentes questions

Arguments :
- df_caract_species (DataFrame) : matrice des espèces (lignes) et de leurs caracteristiques (colonnes) 
avec leur proba
- remaining_species (Vector{Int}) : identifiants des espèces encore possibles
- answer_carac_id (Int) : identifiant de la caractéristique correspondant à la réponse donnée

Sortie :
- new_remaining_species (Vector{Int}) : liste mise à jour des espèces compatibles
"""

function remaining_species_update(df_caract_species::DataFrame,
                                remaining_species::Vector{Int},
                                answer_carac_id::Int)

    # On créé notre nouvelle liste vide d'espèces restantes qu'on va remplir 
    new_remaining_species = Int[]

    # On teste chaque espèce restante
    for sp_id in remaining_species
        # Si l'espèce possède la caractéristique associée à la réponse donnée
        if verif_species_has_caract(df_caract_species, sp_id, [answer_carac_id])
            push!(new_remaining_species, sp_id)
        end
    end

    return new_remaining_species
end

