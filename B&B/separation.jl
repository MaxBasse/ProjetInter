
struct Noeud
    borne_inf::Int
    cle_partielle::Dict{}
end

#On choisit de séparer selon les questions
#C'est-à-dire on regarde toutes les feuilles de l'arbre partielles pour lesquelles on peut encore poser des questions,
#on en choisit une et on énumère toutes les questions à poser possibles.

#On prend un noeud en argument et on rend une liste de noeud à évaluer
function separation(noeud)
    #choix de la feuille partielle pour laquelle faire les branchements
    # i.e parcours de la clé partielle en largeur et on prend la première feuille pour laquelle il reste plusieurs espèces et plusieurs questions
    arbre=noeud.cle_partielle
    feuille, chemin = parcours_largeur(arbre)  #à coder pour avoir le chemin

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
function parcours_largeur(arbre)

    file = [arbre]

    while !isempty(file)
        n = popfirst!(file)

        if haskey(n, "species")
            n_species = length(n["species"])
            n_questions = length(n["questions_accessibles"])
            
            if (n_species > 1) && (n_questions > 0)
                return (n)
            end

        elseif haskey(n, "branches")
            # On ajoute les sous-arbres à la file
            for sous_arbre in values(n["branches"])
                push!(file, sous_arbre)
            end
        end
    end

    return nothing
end


