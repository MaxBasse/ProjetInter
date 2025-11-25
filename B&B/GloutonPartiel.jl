include("../Glouton/fonctions_annexes.jl")

"""
L'idée pour recalculer une possible meilleure borne d'élagage avec un glouton à partir d'une clé partielle :

feuilles = toutes les feuilles de la clé_partielle

pour chaque feuille f : On la remplace par son glouton
    arbre_glouton = glouglouton(... pour cette feuille ...)
    remplacer_feuille(cle, feuille, arbre_glouton)

calculer la profondeur max sur l'arbre total
profondeur_max = profondeur_arbre(cle)

si profondeur_max < borne_sup :
    borne_sup = profondeur_max
    meilleure_solution = clé partielle complétée avec les gloutons

"""

"""
glouglouton : fonction main de l'algo glouton avec des dictionnaire dedictionnaire (cf pseudo-code en photo)

Arguments :
- df_caract_species (DataFrame) : matrice des espèces (lignes) et de leurs caracteristiques (colonnes) 
avec leur proba
- remaining_species (Vector{Int}) : liste des espèces restantes avant la réponse donnée (sous forme d'identifiant/ encodé)
- accessible_questions (Vector{Int}) : liste des questions accessibles à un certain instant (vecteur d'int(identifiant des questions))
- questions_answers (Vector{Vector{Int}}) : liste des réponses possibles (caractéristiques sous forme d'indentifiant) possible pour chaque question
- question_unlock (Vector{Vector{Int}}) : liste des questions débloquées (sous forme d'indentifiant de question) pour chaque réponse/caractéristique obtenue
- asked_questions (Vector{Int}) : liste des questions déjà posées à un certain moment dans l'arbre

Sortie : Retourne notre arbre (noeuds = questions / branches = réponses / feuilles = espèces)
"""



function glouglouton(df_caract_species::BitMatrix, 
                    remaining_species::Vector{Int}, 
                    accessible_questions::Vector{Int},
                    questions_answers::Vector{Vector{Int}},
                    question_unlock::Vector{Vector{Int}},
                    asked_questions::Vector{Int} = Vector{Int}() )

    # Feuille terminale : une seule espèce possible (ou aucune connue)
    if isempty(remaining_species)
        return Dict("species" => [])
    elseif length(remaining_species) == 1
        return Dict("species" => remaining_species)
    elseif isempty(accessible_questions)
        # Plus de questions accessibles → on retourne toutes les espèces restantes car on ne sait pas aller plus loin dans l'identification
        return Dict("species" => remaining_species)
    end

    # 1 et 2 - Choix de la meilleure question (fonction ?)
    (best_question, accessibles_questions, asked_question) = best_question_selection(df_caract_species,
                                                                                    remaining_species,
                                                                                    accessible_questions,
                                                                                    asked_questions,
                                                                                    questions_answers,
                                                                                    question_unlock)

    #Si aucune question n'apporte de nouvelles informations, on rend la liste des espèces restantes                                                                              
    if (best_question==-1)
        return Dict("species" => remaining_species)
    end

    # 3 - Création du noeud de l’arbre
    node = Dict{String, Any}()
    node["question"] = best_question
    node["branches"] = Dict{Int, Any}()
    

    # 4 - Pour chaque réponse possible à cette question 
    for answer_id in questions_answers[best_question]

        # Mise à jour la liste des espèces restantes selon cette réponse (fonction de leodum.jl)
        new_remaining_species = remaining_species_update(df_caract_species,
                                                 remaining_species,
                                                 answer_id)


        # Mise à jour la liste des questions accessibles et des questions posées
        (new_accessible,new_asked_questions) = accessible_questions_update(accessible_questions, 
                                                     asked_questions,
                                                     best_question,
                                                     answer_id,
                                                     question_unlock)


        # Appel récursif : sous-arbre correspondant à cette réponse
        subtree = glouglouton(df_caract_species,
                              new_remaining_species,
                              new_accessible,
                              questions_answers,
                              question_unlock,
                              new_asked_questions)

        # On ajoute la branche au noeud seulement s'il n'est pas vide
        if !(haskey(subtree, "species") && isempty(subtree["species"]))
            node["branches"][answer_id] = subtree
        end

    end

    return node
    

end


# Etape 1 : On récupère toutes les feuilles d'une clé partielle pour réaliser un glouton sur chacune d'entre elles

function feuilles_cle_partielle(noeud::Dict, liste_feuilles::Vector{Dict} = Vector{Dict}())
    if haskey(noeud, "branches") && !isempty(noeud["branches"])
        for (_,fils) in noeud["branches"]
            feuilles_cle_partielle(fils, liste_feuilles)
        end
    else
        push!(liste_feuilles, noeud)
    end
    return liste_feuilles
end


# Etape 2 : On calcul la profondeur de notre arbre généré (DFS)

function profondeur_arbre(arbre::Dict)
    if !haskey(arbre, "branches") || isempty(arbre["branches"])
        return 0
    end
    max_prof = 0
    for (_,fils) in arbre["branches"]
        max_prof = max(max_prof, 1 + profondeur_arbre(fils))
    end
    return max_prof
end

# Etape 3 : Remplacer la feuille par son glouton dans une copie profonde de la clé partielle.

function remplacer_feuille(noeud::Dict, feuille::Dict, arbre_glouton_f::Dict)
    if noeud === feuille
        empty!(noeud)
        merge!(noeud, arbre_glouton_f)
        return true
    end

    if haskey(noeud, "branches")
        for (rep, fils) in noeud["branches"]
            if remplacer_feuille(fils, feuille, arbre_glouton_f)
                return true
            end
        end
    end

    return false
end    



# Etape 4 : Fonction principale appelée par le B&B

function glouton_borne_inf(noeud::Noeud, df_caract_species::BitMatrix, questions_answers::Vector{Vector{Int}}, question_unlock::Vector{Vector{Int}})

    # Copie profonde de la clé partielle
    cle = deepcopy(noeud.cle_partielle)

    # Récupération de toutes les feuilles
    feuilles = feuilles_cle_partielle(cle)

    # Remplacement de chaque feuille par son glouton
    for feuille in feuilles
        remaining   = feuille["especes_restantes"]
        accessibles = feuille["questions_accessibles"]
        posees      = feuille["questions_posees"]

        arbre_glouton = glouglouton(df_caract_species, remaining, accessibles, questions_answers, question_unlock, posees)

        remplacer_feuille(cle, feuille, arbre_glouton)
    end

    # Profondeur max de l'arbre complet
    profondeur_max = profondeur_arbre(cle)

    return profondeur_max, cle
end


# TEST
"""
using CSV, DataFrames



# --- Création d'une clé partielle minimale ---
cle_partielle = Dict(
    "branches" => Dict(
        "f1" => Dict(
            "especes_restantes" => [1, 2],
            "questions_accessibles" => [1, 2, 3],
            "questions_posees" => Int[],
            "branches" => Dict()
        ),
        "f2" => Dict(
            "especes_restantes" => [3, 4],
            "questions_accessibles" => [4, 5, 6],
            "questions_posees" => Int[],
            "branches" => Dict()
        )
    )
)

noeud_test = Noeud(cle_partielle)

# --- Chargement des fichiers CSV ---
using CSV, DataFrames

df_species = CSV.read("species_matrix_petite.csv", DataFrame; header=false)
species_col = CSV.read("species_column_petite.csv", DataFrame)[!, :Species]
characteristics_row = CSV.read("characteristics_row_petite.csv", DataFrame)[!, :Characteristic]

# --- Conversion en BitMatrix ---
df_bit = falses(size(df_species))
for i in 1:size(df_species,1), j in 1:size(df_species,2)
    df_bit[i,j] = df_species[i,j] != 0.0
end

# --- Création des vecteurs questions_answers et question_unlock ---
nb_carac = length(characteristics_row)
questions_answers = [ [i] for i in 1:nb_carac ]  
question_unlock = [ Int[] for _ in 1:nb_carac ]  

# --- Test de la fonction ---
profondeur_max, cle_complete = glouton_borne_inf(noeud_test, df_bit, questions_answers, question_unlock)

println("Profondeur max calculée : ", profondeur_max)
println("Clé complétée : ")
println(cle_complete)


"""