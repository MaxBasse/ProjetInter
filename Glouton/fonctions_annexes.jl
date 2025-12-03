using DataFrames


"""
accessible_questions_update : Met à jour les listes de questions accessibles et déjà posées après une réponse.

# Arguments
- `accessibles_questions::Vector{Int}` : questions actuellement accessibles.
- `asked_questions::Vector{Int}` : questions déjà posées.
- `current_question::Int` : question courante.
- `answer_id::Int` : identifiant de la réponse donnée.
- `question_unlock::Vector{Vector{Int}}` : pour chaque réponse, liste des questions débloquées.

# Retour
Retourne un tuple `(new_accessibles_questions, new_asked_questions)`
"""

function accessible_questions_update(accessibles_questions, asked_questions, current_question, answer_id, question_unlock)
    #On ajoute la question courante aux questions posées
    new_asked_questions = copy(asked_questions)
    push!(new_asked_questions, current_question)

    #On enlève la question courante des questions accessibles
    new_accessibles_questions = filter(x -> x != current_question, accessibles_questions)

    #On rajoute aux questions accessibles les questions débloquées par la réponse donnée
    for q in question_unlock[answer_id]   
        if !(q in new_asked_questions)
            push!(new_accessibles_questions, q)
        end
    end

    return new_accessibles_questions, new_asked_questions
end


"""
score_evaluation : évalue la qualité d'une question en comptant, pour chaque réponse possible, combien d'espèces seraient éliminées

# Arguments
- `df_caract_species::DataFrame` : matrice des espèces (lignes) et de leurs caractéristiques (colonnes), avec valeurs indicatrices ou probabilités.
- `remaining_species::Vector{Int}` : identifiants des espèces encore candidates.
- `current_question::Int` : identifiant de la question à évaluer.
- `question_caract::Vector{Vector{Int}}` : pour chaque question, la liste des colonnes correspondant à ses réponses possibles.

# Retour
- `Int` : taille du plus grand sous-ensemble possible (en fonction des réponses) d’espèces restant pour cette question.  
"""

function score_evaluation(df_caract_species, remaining_species, current_question, question_caract)
    
    #initialisation du score pour chaque réponse
    score=Dict{Int, Int}()
    
    for reponse in question_caract[current_question]

        #On initialise à 0 le nombre d'espèces éliminées par cette réponse de cette question
        score_reponse=0

        #Parcours pour chaque réponse et chaque espèce et on ajoute un si la caractéristique existe
        for espece in remaining_species
            if df_caract_species[espece, reponse]!=0
                score_reponse+=1
            end
        end
        
        score[reponse]=score_reponse
    end

    #Je choisi ici de rendre le max entre |S1| et |S2| car c'est que que je veux minimiser
    return maximum(score)

end


#Meme fonction mais grandement améliorée par chatty (pour éviter les boucles), fonction qui selectionne la fonction qui partitionne le mieux
function score_evaluation2(df_caract_species, remaining_species, current_question, question_caract)

    #Selection des colonnes et des lignes à compter 
    cols = question_caract[current_question]

    rows_to_count = remaining_species

    #comptage des non-zero pour chaque colonne sélectionnées
    score = [sum(df_caract_species[row, col] != 0 for row in rows_to_count; init=0) for col in cols]

    
    #Ne pas choisir les questions qui ne servent à rien
    compteur=0
    for s in score 
        if (s==0)||(s==length(remaining_species))
            compteur+=1
        end
    end
    if (compteur==length(cols))
        #si la question ne partitionne pas les espèces restantes, c'est forcément la (ou une des) pire question donc on la code avec un score de -1
        return -1
    end
    
    #println(score)
    #Je choisi ici de rendre le max entre |S1| et |S2| car c'est que que je veux minimiser
    return maximum(score)

end

# fonction score qui minimise le polymorphisme et le nombre de feuille
function score_evaluation3(df_caract_species, remaining_species, current_question, question_caract)

    #Selection des colonnes et des lignes à compter 
    cols = question_caract[current_question]

    rows_to_count = remaining_species

   # Pour chaque colonne, on récupère l'ensemble des espèces positives
    subset = [ Set(row for row in rows_to_count if df_caract_species[row, col] != 0)
           for col in cols ]

    # Intersection des ensembles
    intersection_species = reduce(intersect, subset)

    # Score = nombre d'espèces dans l'intersection
    score = length(intersection_species)


    
    #Ne pas choisir les questions qui ne servent à rien

    if (score == length(remaining_species))
        #si la question ne partitionne pas les espèces restantes, c'est forcément la (ou une des) pire question donc on la code avec un score de -1
        return -1
    end
    # on regarde si ya pas de set vide dans subst, si oui et que le score est nul c'est que la question ne sert à rien
    any_empty_subset = any(length(s) == 0 for s in subset)

    if score == 0 && any_empty_subset
        return -1   # inutile : un des splits est vide → question inutile
    end

    #println(score)
    #Je choisis ici de le cardinal de l'intersection entre les noeuds fils qui découlent d'une question
    return score

end


function score_evaluation_polymorphism(df_caract_species, remaining_species, current_question, question_caract)
    cols = question_caract[current_question]
    rows_to_count = remaining_species

    subset = [ Set(row for row in rows_to_count if df_caract_species[row, col] != 0)
              for col in cols ]

    intersection_species = reduce(intersect, subset)
    score = length(intersection_species)

    if (score == length(remaining_species))
        return -1
    end
    
    any_empty_subset = any(length(s) == 0 for s in subset)
    if score == 0 && any_empty_subset
        return -1
    end

    return score
end

"""
best_question_selection : sélectionne la meilleure question à poser selon une stratégie basée sur le score d’évaluation

# Arguments
- `df_caract_species::DataFrame` : matrice des espèces (lignes) et de leurs caractéristiques (colonnes), avec valeurs indicatrices ou probabilités
- `remaining_species::Vector{Int}` : identifiants des espèces encore candidates
- `accessible_questions::Vector{Int}` : liste des questions actuellement accessibles 
- `question_caract::Vector{Vector{Int}}` : pour chaque question, liste des caractéristiques correspondant à ses réponses possibles

# Retour
- `Int` : identifiant de la question optimale selon la stratégie choisie
"""

function best_question_selection(df_caract_species, remaining_species, accessible_questions, asked_questions, question_caract, question_unlock)
    #initialisation du score pour chaque question
    score=Dict{Int, Int}()

    new_asked_questions = copy(asked_questions)
    new_accessibles_questions = copy(accessible_questions)

    #Calcul du score pour chaque question accessible
    for question in accessible_questions
        score[question] = score_evaluation_polymorphism(df_caract_species, remaining_species, question, question_caract)
        if (score[question]==-1)
            #On met à jour les questions posées et les questions accessibles
            push!(new_asked_questions, question)
            filter(x -> x !=question, new_accessibles_questions)

            #A décommenter si on veut rajouter les unlock_question des questions qu'on enlève mais je sais pas pourquoi ça ne change rien sur l'arbre final...
            #=
            #Il faut quand même unlock les questions associées aux réponses où les espèces peuvent être :
            cols = question_caract[question]
            rows_to_count = remaining_species
            score_question = [sum(df_caract_species[row, col] != 0 for row in rows_to_count; init=0) for col in cols]
            for i in eachindex(score_question, cols)
                s=score_question[i]
                c=cols[i]
                if (s==length(remaining_species))
                    #On rajoute aux questions accessibles les questions débloquées par les réponses des questions non-posées
                    for q in question_unlock[c]   
                        if !(q in new_asked_questions)
                            push!(new_accessibles_questions, q)
                        end
                    end
                end
            end
            =#

            delete!(score, question)
        end
    end

    if isempty(score)
        return -1, new_accessibles_questions, new_asked_questions
    end

    #On choisit la question possèdant le plus petit score
    #println(score)
    return findmin(score)[2], new_accessibles_questions, new_asked_questions

end


"""
Retourne les questions accessibles pour lesquelles toutes les especes restantes
donnent la meme reponse.
- df_caract_species : matrice especes x caracteristiques
- remaining_species : vecteur des indices des especes restantes
- accessible_questions : questions encore accessibles
- question_caract : pour chaque question, liste des colonnes correspondantes
"""
function obvious_questions(df_caract_species, remaining_species, accessible_questions, question_caract)
    evidentes = Int[]
    for q in accessible_questions
        cols = question_caract[q]
        # Extraire les reponses des especes restantes pour cette question
        reponses = [df_caract_species[s, cols] for s in remaining_species]
        # On regarde si toutes les reponses sont identiques
        if all(r -> r == reponses[1], reponses)
            push!(evidentes, q)
        end
    end
    return evidentes
end




"""
verif_species_has_caract : Fonction de vérification d'appartenance d'une caractéristique pour une espèce

Arguments :
- df_caract_species (DataFrame) : matrice des espèces (lignes) et de leurs caracteristiques (colonnes) avec leur proba
- species_id (Int) : identifiant (index de ligne) de l’espèce à vérifier
- caract_ids (Vector{Int}) : identifiants (index de colonnes) des caractéristiques à tester

Sortie :
- Booléen (true si l’espèce possède toutes les caractéristiques demandées, false sinon)
"""
function verif_species_has_caract(df_caract_species::BitMatrix,
                                  species_id::Int,
                                  caract_ids::Vector{Int})

    # vérifs d'erreurs d'identifiants
    if species_id > size(df_caract_species,1)
        error("Identifiant d'espèce $(species_id) hors limites du DataFrame.")
    end

    if any(x -> x > size(df_caract_species,2), caract_ids)
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

function remaining_species_update(df_caract_species::BitMatrix,
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