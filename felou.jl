import Pkg
Pkg.add("JSON")
using JSON
donnees = JSON.parsefile("data.json")
donnees_tronquees = JSON.parsefile("truncated_data.json")

#println(donnees)
println(donnees["questions"][1]["title_q"])
println(donnees["questions"][1]["answers"][1]["title_a"])
println(donnees["questions"][2]["title_q"])



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



liste_questions=liste_question2(donnees_tronquees["questions"])
println(length(liste_questions))

f

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



