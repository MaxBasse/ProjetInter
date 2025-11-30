include("GloutonPartiel.jl")
include("../Glouton/glouton.jl")
include("separation.jl")
include("Evaluation3.jl")

function Branch_and_Bound(Qa_initial, E_initial, df_caract_species, question_unlock, questions_answers)

    # --- 1. Initialisation ---
    # On lance un glouton pour avoir une première borne sup
    sol_glouton = glouglouton(df_caract_species, E_initial, Qa_initial, questions_answers, question_unlock)
    borne_sup = profondeur_arbre(sol_glouton)
    meilleure_solution = sol_glouton
    
    println("Borne Supérieure Initiale (Glouton) : $borne_sup")

    racine = Noeud(
        Dict(
            "profondeur" => 0,
            "questions_accessibles" => copy(Qa_initial),
            "questions_posees" => Int[],
            "especes_restantes" => copy(E_initial),
        ), 
        0
    )
    # Calcul de la borne inf de la racine
    racine.borne_inf = evaluation(racine, df_caract_species, questions_answers) # Notez l'ajout de df_caract_species ici
    
    ListeNoeuds = [racine]
    compteur = 0

    # --- 2. Boucle Principale ---
    while !isempty(ListeNoeuds)
        compteur += 1
        
        # STRATÉGIE DFS (Profondeur) : On prend toujours le dernier ajouté (LIFO)
        # On NE trie PLUS la liste globale, ce qui évite l'effet "parcours en largeur"
        noeud = pop!(ListeNoeuds)

        # Élasticité (si le nœud est devenu inutile entre temps)
        if noeud.borne_inf >= borne_sup
            continue 
        end

        # Test si solution complète
        if Est_une_cle_determination_totale(noeud)
            cout_solution = profondeur_arbre(noeud.cle_partielle)
            if cout_solution < borne_sup
                borne_sup = cout_solution
                meilleure_solution = noeud.cle_partielle
                println(">>> AMÉLIORATION TROUVÉE : Coût $borne_sup <<<")
                
                # NETTOYAGE : On filtre la pile pour retirer tout ce qui est désormais inutile
                # C'est ici qu'on réduit la taille de la pile drastiquement !
                filter!(n -> n.borne_inf < borne_sup, ListeNoeuds)
                println("    (Pile nettoyée : $(length(ListeNoeuds)) noeuds restants)")
            end
        else
            # --- Branchement ---
            noeud_inter = separation(noeud, questions_answers, question_unlock, df_caract_species)
            
            # Filtrage et Calcul des bornes des enfants
            enfants_valides = Noeud[]
            for child in noeud_inter
                child.borne_inf = evaluation(child, df_caract_species, questions_answers)
                if child.borne_inf < borne_sup
                    push!(enfants_valides, child)
                end
            end
            
            # HEURISTIQUE DE TRI LOCAL : 
            # On veut mettre les MEILLEURS enfants à la fin du vecteur 'enfants_valides', 
            # car pop! prend le dernier élément.
            # Critère : On veut explorer ceux qui ont la plus PETITE borne inf en premier.
            # Donc on trie par borne_inf décroissante (le plus petit sera à la fin).
            sort!(enfants_valides, by = x -> x.borne_inf, rev = true)
            
            # Ajout à la pile principale
            append!(ListeNoeuds, enfants_valides)
            
            # --- Optimisation Gloutonne Locale (Optionnel mais recommandé) ---
            # On lance un glouton rapide sur ce noeud pour voir si on peut battre le record
            # Cela permet de mettre à jour borne_sup plus vite
            bs_locale, sol_locale = glouton_borne_inf(noeud, df_caract_species, questions_answers, question_unlock)
            if bs_locale < borne_sup
                borne_sup = bs_locale
                meilleure_solution = sol_locale
                println(">>> GLOUTON LOCAL A TROUVÉ MIEUX : Coût $borne_sup <<<")
                filter!(n -> n.borne_inf < borne_sup, ListeNoeuds)
            end
        end
        
        # Log périodique pour rassurer
        if compteur % 100 == 0
             println("Iter: $compteur | Pile: $(length(ListeNoeuds)) | Best: $borne_sup | Profondeur noeud: $(noeud.cle_partielle["profondeur"])")
        end
    end

    return meilleure_solution, borne_sup
end

function Est_une_cle_determination_totale(noeud::Noeud)
    return cle_totale_recursive(noeud.cle_partielle)
end

function cle_totale_recursive(cle::Dict{Any,Any})::Bool

    # Si la clé n'a pas de branches -> c’est une feuille
    if !haskey(cle, "branches") || isempty(cle["branches"])
        nb = length(cle["especes_restantes"])
        return nb <= 1
    end

    # Sinon, descente récursive dans chaque sous-branche
    for (_, souscle) in cle["branches"]
        if !cle_totale_recursive(souscle)
            return false
        end
    end

    return true
end