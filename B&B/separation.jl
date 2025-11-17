using JSON


mutable struct Noeud
    borne_inf::Int
    cle_partielle::Dict
end

#On choisit de séparer selon les questions
#C'est-à-dire on regarde toutes les feuilles de l'arbre partielles pour lesquelles on peut encore poser des questions,
#on en choisit une et on énumère toutes les questions à poser possibles.

#On prend un noeud en argument et on rend une liste de noeud à évaluer
function separation(noeud)
    #choix de la feuille partielle pour laquelle faire les branchements
    # i.e parcours de la clé partielle en largeur et on prend la première feuille pour laquelle il reste plusieurs espèces et plusieurs questions
    arbre=noeud.cle_partielle
    (feuille, chemin) = parcours_largeur(arbre) 

    res=[]
    #j'énumère pour chaque question accessible de la feuille
    for q in feuille["questions_assessibles"]
        #création de la clé partielle associée
        nouvelle_cle_partielle = MAJ_cle_partielle(arbre, chemin, q) #à coder
        #création du nouveau noeud
        nouveau_noeud = Noeud(0, nouvelle_cle_partielle)
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

        if haskey(n, "species")
            n_species = length(n["species"])
            #n_questions = length(n["questions_accessibles"])
            
            if (n_species > 1) #&& (n_questions > 0)
                return (n, chemin)
            end

        elseif haskey(n, "branches")
            # On ajoute les sous-arbres à la file, et les chemins correspondants
            for (cle, sous_arbre) in n["branches"]
                push!(file, (sous_arbre, vcat(chemin,cle)))
            end
        end
    end

    return -1
end

#Fonction qui met à jour la clé partielle associée au nouveau noeud, en fontion de l'ancienne clé partielle et de la séparation choisie
#Je n'ai pas encore codé le chemin, mais je considère que c'est un vecteur, avec les identifiants des chemins suivis (id --> "branche" --> id --> ... --> id --> "feuille")
function MAJ_cle_partielle(arbre, chemin, q)
    feuille = chemin[end]
    pop!(chemin)

    iter=arbre
    for i in chemin
        iter=iter["branches"][i]
    end

    question_accessibles=iter[feuille]["questions_accessibles"]
    especes_restantes=iter[feuille]["species"]

    branchage=dict()
    for reponse in questions_answers[q] #pour toutes les réponses possibles à la question q
        #faire tout plein de manips, potentiellement dans des fonctions annexes, qui vont me donner les nouvelles espèces_restantes et les nouvelles questions_accessibles
        new_questions_accessibles , new_especes_restantes = MAJ(question_accessibles, especes_restantes, reponse) #à coder

        #création des nouvelles branches
        branchage[reponse]=dict()
        branchage[reponse]["questions_accessibles"] = new_questions_accessibles
        branchage[reponse]["species"] = new_especes_restantes
    end

    #mettre à jour l'arbre général, pour l'instant je vois pas trop comment faire
    #apparement, faire "iter=arbre" et ensuite modifier iter. Cela modifie aussi arbre (car pas une recopie)
    #on peut donc imaginer un truc comme ça mais à vérifier
    iter=branchage

    #rendre l'arbre actualisé
    return arbre
end


#tests
arbre = JSON.parsefile("c:/Users/HP/Documents/4MA/Projet interdisciplinaire/ProjetInter/Glouton/arbre.json")
parcours_largeur(arbre)
