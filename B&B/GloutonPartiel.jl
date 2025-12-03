include("../Glouton/fonctions_annexes.jl")
"""
    glouglouton(df_caract_species::BitMatrix, remaining_species::Vector{Int}, accessible_questions::Vector{Int},questions_answers::Vector{Vector{Int}}, question_unlock::Vector{Vector{Int}}, asked_questions::Vector{Int} = Vector{Int}())

#Arguments :
- `df_caract_species::BitMatrix` : Matrice binaire contenant les caractéristiques des espèces.
- `remaining_species::Vector{Int}` : Liste des indices des espèces restantes à identifier.  
- `accessible_questions::Vector{Int}` : Liste des indices des questions accessibles.
- `questions_answers::Vector{Vector{Int}}` : Pour chaque question, liste des indices des réponses (caractéristiques) possibles.
- `question_unlock::Vector{Vector{Int}}` : Pour chaque caractéristique, liste des indices des questions débloquées.
- `asked_questions::Vector{Int}` : Liste des indices des questions déjà posées (par défaut vide).

#Returns :
- `node::Dict{String, Any}` : Dictionnaire représentant le noeud de l'arbre de décision construit par l'algorithme glouton.

# Exemple
    df_caract_species = BitMatrix(...) # Matrice binaire des caractéristiques des espèces
    remaining_species = [1, 2, 3, 4, 5]
    accessible_questions = [1, 2, 3, 4, 5]
    questions_answers = [[10, 20], [30, 40], ...] # Liste des réponses possibles pour chaque question
    question_unlock = [[2, 3], [4], ...] # Liste des questions débloquées par chaque caractéristique

    arbre_glouton = glouglouton(df_caract_species, remaining_species, accessible_questions, questions_answers, question_unlock)
"""
function glouglouton(df_caract_species::BitMatrix, 
                    remaining_species::Vector{Int}, 
                    accessible_questions::Vector{Int},
                    questions_answers::Vector{Vector{Int}},
                    question_unlock::Vector{Vector{Int}},
                    asked_questions::Vector{Int} = Vector{Int}())

    # Feuille terminale : une seule espèce possible (ou aucune connue)
    if isempty(remaining_species)
        return Dict("species" => [])
    elseif length(remaining_species) == 1
        return Dict("species" => remaining_species)
    elseif isempty(accessible_questions)
        # Plus de questions accessibles → on retourne toutes les espèces restantes car on ne sait pas aller plus loin dans l'identification
        return Dict("species" => remaining_species)
    end

    # --- Gestion des questions évidentes ---
    while true
        q_obv = obvious_questions(df_caract_species, remaining_species, accessible_questions, questions_answers)
        if isempty(q_obv)
            break
        end

        for q in q_obv
            # Marque comme posee
            push!(asked_questions, q)
            filter!(x -> x != q, accessible_questions)

            # Ajoute les questions debloquees par cette reponse
            for c in questions_answers[q]
                for new_q in question_unlock[c]
                    if !(new_q in asked_questions) && !(new_q in accessible_questions)
                        push!(accessible_questions, new_q)
                    end
                end
            end
        end
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





