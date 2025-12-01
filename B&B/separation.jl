using JSON


#On choisit de séparer selon les questions
#C'est-à-dire on regarde toutes les feuilles de l'arbre partielles pour lesquelles on peut encore poser des questions,
#on en choisit une et on énumère toutes les questions à poser possibles.

#On prend un noeud en argument et on rend une liste de noeud à évaluer
function separation(noeud, questions_answers, question_unlock, df_caract_species)
    #choix de la feuille partielle pour laquelle faire les branchements
    # i.e parcours de la clé partielle en largeur et on prend la première feuille pour laquelle il reste plusieurs espèces et plusieurs questions
    arbre=noeud.cle_partielle
    (feuille, chemin) = parcours_largeur(arbre) 

    res=Noeud[]
    q_a = feuille["questions_accessibles"]
    
    #j'énumère pour chaque question accessible de la feuille
    for q in q_a
        #création de la clé partielle associée
        nouvelle_cle_partielle = MAJ_cle_partielle(arbre, chemin, q, questions_answers, question_unlock, df_caract_species)
        #création du nouveau noeud
        nouveau_noeud = Noeud(nouvelle_cle_partielle, 0)
        #ajout à la liste des nouveaux noeuds
        push!(res, nouveau_noeud)
    end
    
    return res

end



#Fonction qui rend la première feuille partielle trouvée, et le chemin associé pour y aller
#Attention, à vérifier pour le chemin
function parcours_largeur(arbre)

    file = [(arbre,[])]

    while !isempty(file)
        n, chemin = popfirst!(file)

        if !haskey(n, "branches") || isempty(n["branches"])
            n_species = length(n["especes_restantes"])
            #n_questions = length(n["questions_accessibles"])
            
            if (n_species > 1) #&& (n_questions > 0)
                return (n, chemin)
            end

        elseif haskey(n, "branches") && !isempty(n["branches"])
            # On ajoute les sous-arbres à la file, et les chemins correspondants
            for (cle, sous_arbre) in pairs(n["branches"])
                push!(file, (sous_arbre, vcat(chemin,cle)))
            end
        end
    end

    return -1
end

#Fonction qui met à jour la clé partielle associée au nouveau noeud, en fontion de l'ancienne clé partielle et de la séparation choisie
#Je n'ai pas encore codé le chemin, mais je considère que c'est un vecteur, avec les identifiants des chemins suivis (id --> "branche" --> id --> ... --> id --> "feuille")
function MAJ_cle_partielle(arbre, chemin, q, questions_answers, question_unlock, df_caract_species)
    new_arbre = deepcopy(arbre)


    if isempty(chemin)
        noeud_feuille=new_arbre
    else
        local_path = copy(chemin)
        feuille = pop!(local_path)

        iter=new_arbre
        for i in local_path
            iter=iter["branches"][i]
        end
        noeud_feuille = iter["branches"][feuille]
    end

    questions_accessibles = copy(noeud_feuille["questions_accessibles"])
    especes_restantes = copy(noeud_feuille["especes_restantes"])
    questions_posees = copy(noeud_feuille["questions_posees"])
    profondeur = copy(noeud_feuille["profondeur"])

    #println(questions_accessibles)

    noeud_feuille["question"]=q
    
    branchage = Dict{Any,Any}()
    for reponse in questions_answers[q] #pour toutes les réponses possibles à la question q
        #faire tout plein de manips, potentiellement dans des fonctions annexes, qui vont me donner les nouvelles espèces_restantes et les nouvelles questions_accessibles
        new_questions_accessibles , new_questions_posees = MAJ_questions(questions_accessibles, questions_posees, q, reponse, question_unlock)
        new_especes_restantes = MAJ_especes_restantes(df_caract_species, especes_restantes, reponse)

        #création des nouvelles branches
        branchage[reponse]=Dict{Any,Any}()
        branchage[reponse]["questions_accessibles"] = new_questions_accessibles
        branchage[reponse]["questions_posees"] = new_questions_posees
        branchage[reponse]["profondeur"] = profondeur + 1
        branchage[reponse]["especes_restantes"] = new_especes_restantes
        #branchage[reponse]["branches"] = Dict()

    end
    noeud_feuille["branches"]=branchage

    

    #mettre à jour l'arbre général, pour l'instant je vois pas trop comment faire
    #apparement, faire "iter=arbre" et ensuite modifier iter. Cela modifie aussi arbre (car pas une recopie)
    #on peut donc imaginer un truc comme ça mais à vérifier
    

    #rendre l'arbre actualisé
    return new_arbre
end













function MAJ_questions(accessibles_questions, asked_questions, current_question, answer_id, question_unlock)
    #On ajoute la question courante aux questions posées
    new_asked_questions = copy(asked_questions)
    push!(new_asked_questions, current_question)

    #On enlève la question courante des questions accessibles
    new_accessibles_questions = filter(x -> x != current_question, accessibles_questions)

    #On rajoute aux questions accessibles les questions débloquées par la réponse donnée
    for q in question_unlock[answer_id]   
        if !(q in new_asked_questions) && !(q in new_accessibles_questions)
            push!(new_accessibles_questions, q)
        end
    end

    return new_accessibles_questions, new_asked_questions
end


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

function MAJ_especes_restantes(df_caract_species::BitMatrix,
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



