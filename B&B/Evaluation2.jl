"""
Evaluation pour déterminer une borne inf sur le coût d'une clé de détermination
On calcule la profondeur minimale nécessaire pour séparer les espèces restantes
en utilisant le "facteur de branchement effectif" des questions restantes.
"""
function evaluation(n::Noeud, df_caract_species::BitMatrix, vect_question_carac::Vector{Vector{Int}})
    cle_partielle = n.cle_partielle
    feuille_iterator = feuilles_cle_partielle(cle_partielle)
    cout_max = 0
    
    # Nombre total de questions (déduit de la taille du vecteur de mapping)
    nb_total_questions = length(vect_question_carac)

    for feuille in feuille_iterator
        especes = feuille["especes_restantes"]
        n_sp = length(especes)

        # Si 0 ou 1 espèce, le coût est simplement la profondeur actuelle (pas de questions supp. nécessaires)
        if n_sp <= 1
            if feuille["profondeur"] > cout_max
                cout_max = feuille["profondeur"]
            end
            continue
        end

        # On considère TOUTES les questions non posées comme candidates (Optimisme pour la Borne Inf)
        # Cela garantit que la borne est valide (<= coût réel) même si une "super question" est verrouillée.
        remaining_q = setdiff(1:nb_total_questions, feuille["questions_posees"])

        # Calculer le pouvoir de séparation RÉEL de chaque question sur ce sous-ensemble d'espèces
        effective_branching_factors = Int[]

        for q in remaining_q
            reponses_possibles = vect_question_carac[q]
            nb_branches_actives = 0
            
            # Pour chaque réponse possible à la question q
            for rep_id in reponses_possibles
                # On regarde si AU MOINS UNE des espèces restantes possède cette caractéristique
                # (Optimisation : on utilise view ou une boucle rapide)
                has_species = false
                for sp_id in especes
                    if df_caract_species[sp_id, rep_id]
                        has_species = true
                        break
                    end
                end
                
                if has_species
                    nb_branches_actives += 1
                end
            end

            # Si une question divise le groupe en k sous-groupes, son facteur est k.
            # Si k=1, la question ne sépare rien (inutile pour la borne inf).
            if nb_branches_actives > 1
                push!(effective_branching_factors, nb_branches_actives)
            end
        end

        # Trier les facteurs de branchement par ordre décroissant (Stratégie Gloutonne Optimiste)
        sort!(effective_branching_factors, rev=true)

        # Simuler la séparation des espèces
        current_groups = 1
        depth_added = 0
        
        # Tant qu'on n'a pas assez de "feuilles théoriques" pour distinguer toutes les espèces
        while current_groups < n_sp
            depth_added += 1
            if depth_added <= length(effective_branching_factors)
                # On multiplie par le meilleur facteur de branchement disponible à ce niveau
                current_groups *= effective_branching_factors[depth_added]
            else
                # Si on a épuisé les questions utiles mais qu'il reste des espèces,
                # on ne peut techniquement pas les séparer. 
                # Pour la borne, on ajoute 1 par niveau restant (pire cas linéaire) ou on arrête.
                # Ici on suppose qu'on continue à séparer au moins par 2 (optimiste) ou on break.
                # Pour garantir une borne inf stricte : si on ne peut plus séparer, le coût est infini.
                # Mais pour l'algo, on va juste incrémenter.
                current_groups *= 2 
            end
        end

        cout_feuille = feuille["profondeur"] + depth_added
        
        if cout_feuille > cout_max
            cout_max = cout_feuille
        end
    end

    return cout_max
end