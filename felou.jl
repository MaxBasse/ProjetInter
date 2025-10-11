using JSON
using CSV
using DataFrames


donnees = JSON.parsefile("data.json")
donnees_tronquees = JSON.parsefile("truncated_data.json")
donnees_matrice = CSV.read("species_matrix.csv", DataFrame, header=false)
#println(donnees_matrice[1,:])

#Test de lecture des données
#println(donnees)
#println(donnees["questions"][1]["title_q"])
#println(donnees["questions"][1]["answers"][1]["title_a"])
#println(donnees["questions"][2]["title_q"])



#Fonction qui rend le dictionnaire de toutes les questions (en id) avec une liste des réponses associées
function liste_question(data)
    res = Dict{String, Vector{String}}()
    
    #Parcours de toutes les questions primaires
    for q in data
        id_q = q["title_q"]
        l = String[]
        
        # Récupérer toutes les réponses
        for a in q["answers"]
            push!(l, a["title_a"])
            
            # Si cette réponse débloque des questions supplémentaires, on fait un appel récursif pour prendre en compte toutes les questions
            if !isempty(a["unlock_questions"])
                sous_res = liste_question(a["unlock_questions"])
                merge!(res, sous_res)
            end
        end
        
        #On ajoute au réslutat la question avec sa liste des réponses 
        res[id_q] = l
    end
    
    return res
end



liste_questions=liste_question(donnees_tronquees["questions"])
#println(liste_questions)
println(length(liste_questions))


#fonction qui calcule le score pour une question, à un moment donné du parcours de l'arbre
    # But : rendre le nombre d'espèces qui sont éliminées par cette question (dans le but de le maximiser)
    # <=> question qui split au mieux les caractéristiques 
    # ATTENTION au polymorphisme !!! (dans un second temps)
    # <=> rendre le nb d'espèces pour lesquelles cette question n'a pas de polymorphisme + le plus de réponses possibles

#Pour cette fonction, je calcule le nombre d'espèces éliminées par la réponse à cette question
    #je suppose que j'ai accès à la liste des questions (liste_question), avec les réponses possibles pour chaque question (à coder ci-dessus)
    #je suppose aussi avoir une matrice réponses/caractéristiques (celle de Tutur)
function score_question(especes_restantes, question, matrice)
    
    #initialisation du score pour chaque réponse
    score=Dict{String, Float64}()
    
    for reponse in liste_question[question]
        
        #Mise en forme de l'identifiant pour pouvoir utiliser la matrice de Tutur (à adapter en fonction)
        id_reponse=question["title_q"]+"_"+reponse["title_a"]

        #On initialise à 0 le nombre d'espèces éliminées par cette réponse de cette question
        score_reponse=0
        #Parcours pour chaque réponse et chaque espèce et on ajoute un si la caractéristique n'existe pas (donc si la case de la matrice vaut 0)
        for espece in especes_restantes
            if matrice[espece][id_reponse]==0
                score_reponse+=1
            end
        end
        score[reponse]=score_reponse
    end

    #Ici je retourne le min pour voir combien d'espece au minimum on supprime mais on pourrait prendre la moyenne par exemple
    return min(score)

end


#Fonction MAJ accessibles_questions et asked_questions
#Prend en arguments accessibles_questions, asked_questions et l'id de la question/réponse courante
#rend accessibles_questions et asked_questions (mis à jour) sous forme de tuple 

function update_accessibles_questions(accessibles_questions, asked_questions, id_Q_R)
    current_question = question_id(id_Q_R)  #fct à coder
    asked_questions=asked_questions + current_question
    accessibles_questions = accessibles_questions - current_question
    for q in question_unlock[id_Q_R]    #question_unlock correspond à une liste donnée au début
        if !(q in asked_questions)
            accessibles_questions = accessibles_questions + Q
        end
    end
    return accessibles_questions, asked_questions
end






#Forme de l'arbre : 
#Dictionnaire de dictionaire... Avec id=1ère question et valeur = dictionnaire avec id=réponse et valeurs=questions correspondant aux questions suivantes, etc

#Idée que je me fais de l'algorithme pour créer l'arbre :

#avoir une variable "questions_accessibles" qui listes les questions que l'on a le droit de pousser
#avoir une variable "especes_restantes" qui liste les espèces qui peuvent encore correspondre aux réponses données

#tant que length(especes_restantes)>1 ou questions toutes posées
    #calculer le score de chaque question (avec la fonction score_question(especes_restantes, question, matrice))
    #choisir la question avec le meilleur score, la poser, puis explorer les possibilités de réponse
    #une fois la questions choisie, on a un noeud et les réponses à cette question sont les transitions vers les futures réponses
    #on remet à jour "espèces restantes" et "questions accessibles"

#une fois qu'on a fini un chemin, on met le nom de l'espèce comme valeur finale 
#et on revient au noeud précédent pour explorer les autres possibilités

#utiliser la récursivité ? C'est le mieux je pense mais la je vois pas comment gérer "question_accessibles" et "especes_restantes"

#= Pseudo code donné par chat

fonction construire_arbre(questions_accessibles, especes_restantes, matrice):

    # Cas d'arrêt 1 : une seule espèce restante → feuille
    si longueur(especes_restantes) == 1:
        retourner nom_de_cette_espece(especes_restantes)

    # Cas d'arrêt 2 : aucune question restante → feuille ambiguë
    si questions_accessibles est vide:
        retourner liste_des_especes(especes_restantes)

    # Étape 1 : évaluer chaque question possible
    scores = dictionnaire_vide()
    pour chaque q dans questions_accessibles:
        scores[q] = score_question(especes_restantes, q, matrice)
        # (fonction externe : score_question → calcule la capacité de la question
        # à bien séparer les espèces restantes, par ex. entropie ou équilibre des réponses)

    # Étape 2 : choisir la meilleure question
    meilleure_question = argmax(scores)

    # Étape 3 : créer un nœud (clé = meilleure_question)
    noeud = dictionnaire()
    noeud["id_question"] = meilleure_question
    noeud["branches"] = dictionnaire()

    # Étape 4 : explorer chaque réponse possible à cette question
    reponses_possibles = reponses_de_question(meilleure_question, especes_restantes, matrice)
    # (fonction externe : retourne la liste des réponses distinctes présentes
    # pour les espèces encore candidates)

    pour chaque r dans reponses_possibles:
        # Mettre à jour la liste des espèces compatibles avec cette réponse
        nouvelles_especes = filtrer_especes(especes_restantes, meilleure_question, r, matrice)
        # (fonction externe : ne garde que les espèces qui donnent la réponse r à la question choisie)

        # Mettre à jour la liste des questions accessibles
        nouvelles_questions = maj_questions(questions_accessibles, meilleure_question, nouvelles_especes)
        # (fonction externe : enlève la question déjà posée, et éventuellement ajoute d'autres
        # qui ne deviennent pertinentes que maintenant)

        # Récursion : construire le sous-arbre pour cette réponse
        sous_arbre = construire_arbre(nouvelles_questions, nouvelles_especes, matrice)

        # Ajouter cette branche dans le dictionnaire
        noeud["branches"][r] = sous_arbre

    retourner noeud
=#







#Pseudo-code donné dans le rapport de stage :

#=
Algorithme 1 : ID3(Q,S,maxdepth)
Entr´ees : Q ⊆ P(V), S un ensemble d’especes, maxdepth un entier
Sorties : un arbre de d´ecision pour Q et S de taille inf´erieure `a maxdepth
1 FunRec Recurse(I ) :
2 σ ← etat(I)
3 si caracteres = ∅ ou |I| = maxdepth alors
4 retourner Feuille(σ)
5 si ∃ s ∈ σ, σ(s) > .8 alors
6 retourner Feuille(σ)
7 i ← caract`ere `a scoreσ minimal
8 enfants ← [ (k, Recurse(I ∪ {(i, k)}])) pour k ∈ Vi ]
9 retourner Noeud(σ, i, enfants)
10 Recurse(∅,+∞)
=#
 