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
    return max(score)

end


#Meme fonction mais grandement améliorée par chatty (pour éviter les boucles)
function score_evaluation2(df_caract_species, remaining_species, current_question, question_caract)

    #Selection des colonnes et des lignes à compter 
    cols = question_caract[current_question]

    rows_to_count = remaining_species

    #comptage des non-zero pour chaque colonne sélectionnées
    #score = [sum(df_caract_species[row, col] != 0 for row in rows_to_count) for col in cols]
    score = [sum(df_caract_species[row, col] != 0 for row in remaining_species; init=0) for col in cols]


    #Je choisi ici de rendre le max entre |S1| et |S2| car c'est que que je veux minimiser
    return maximum(score)

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

function best_question_selection(df_caract_species, remaining_species, accessible_questions, question_caract)
    #initialisation du score pour chaque question
    score=Dict{Int, Int}()

    #Calcul du score pour chaque question accessible
    for question in accessible_questions
        score[question] = score_evaluation2(df_caract_species, remaining_species, question, question_caract)
    end

    #On choisit la question possèdant le plus petit score
    println(score)
    return findmin(score)[2]

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