#include("leodum.jl")
include("questions_parser.jl")
include("data_parsing.jl")
include("fonctions_annexes.jl")


using AbstractTrees
using DataFrames
using Random
using JSON


# A struct to represent a node in the decision tree.
# It can be either an internal (question) node or a leaf (species) node.
mutable struct DiagnosisNode
    # If the node is a question node, this holds the question ID (Int).
    # If it's a leaf node, this is -1.
    question_id::Int 
    
    # If the node is a leaf, this holds the list of remaining species IDs (Vector{Int}).
    # If it's a question node, this is empty.
    species_ids::Vector{Int} 
    
    # The branches/children of the node. 
    # Key: Answer ID (Int), Value: Child DiagnosisNode
    branches::Dict{Int, DiagnosisNode} 

    # Constructor for an internal (question) node
    function DiagnosisNode(question_id::Int)
        new(question_id, Int[], Dict{Int, DiagnosisNode}())
    end

    # Constructor for a leaf (species) node
    function DiagnosisNode(species_ids::Vector{Int})
        new(-1, species_ids, Dict{Int, DiagnosisNode}())
    end
end

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
                    asked_questions::Vector{Int} )

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
## Test du glouton sur nos données

#Initialisation des données
remaining_species=collect(1:size(species_matrix)[1])
asked_questions = Vector{Int}()

accessible_questions = Vector{Int}()
data = JSON.parsefile("data.json")
for q in data["questions"]
    push!(accessible_questions, findfirst(==(q["title_q"]), vect_question))
end


for answer_id in vect_question_carac[35]
    new_remaining_species = remaining_species_update(species_matrix, remaining_species, answer_id)
    println("Answer ", answer_id, " → remaining_species = ", new_remaining_species)
end

new_species_matrix = copy(species_matrix)
for reponses in vect_question_carac
    rowsums = vec(sum(new_species_matrix[:, reponses], dims=2))
    for i in axes(new_species_matrix, 1)
        if rowsums[i] == 0
            new_species_matrix[i, reponses] .= 1
        end
    end
end


best_question_selection(new_species_matrix, remaining_species, accessible_questions, asked_questions, vect_question_carac, vect_unlock_q)

#Application de l'algo
arbre=glouglouton(new_species_matrix, remaining_species, accessible_questions, vect_question_carac, vect_unlock_q, asked_questions)
arbre_json=JSON.json(arbre, 4)

open("arbre.json", "w") do f
    write(f, arbre_json)
end

