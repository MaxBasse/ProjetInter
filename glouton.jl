include("leodum.jl")
include("felou.jl")

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

function glouglouton(df_caract_species::DataFrame, 
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
    best_question = best_question_selection(df_caract_species,
                                            remaining_species,
                                            accessible_questions,
                                            questions_answers)

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


        # Mise à jour la liste des questions accessibles (fonction ?)
        new_accessible = accessible_questions_update(accessible_questions,
                                                     best_question,
                                                     answer_id,
                                                     question_unlock)

         # Mise à jour de la liste des questions posées pour cette branche/réponse
        new_asked_questions = copy(asked_questions)
        push!(new_asked_questions, best_question)

        # Appel récursif : sous-arbre correspondant à cette réponse
        subtree = glouglouton(df_caract_species,
                              new_remaining_species,
                              new_accessible,
                              questions_answers,
                              question_unlock,
                              new_asked_questions)

        # On ajoute la branche au noeud
        node["branches"][answer_id] = subtree
    end

    return node
    


end
