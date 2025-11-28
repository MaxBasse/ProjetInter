"""
Evaluation pour déterminer une borne inf sur le coût d'une clé de détermination.

Stratégie "Min-Max Cluster" (Plus agressive) :
Au lieu de supposer une division parfaite, on simule la séparation des espèces
en regardant à chaque étape quelle question permet de minimiser la taille du 
plus gros paquet d'espèces restant (le pire cas).
Cela capture le fait que certaines espèces sont difficiles à séparer (branches profondes).
"""
function evaluation(n::Noeud, df_caract_species::BitMatrix, vect_question_carac::Vector{Vector{Int}})
    cle_partielle = n.cle_partielle
    feuille_iterator = feuilles_cle_partielle(cle_partielle)
    cout_max = 0
    
    # Nombre total de questions
    nb_total_questions = length(vect_question_carac)

    for feuille in feuille_iterator
        especes = copy(feuille["especes_restantes"])
        profondeur_actuelle = feuille["profondeur"]
        
        # S'il reste 0 ou 1 espèce, la branche est finie
        if length(especes) <= 1
            if profondeur_actuelle > cout_max
                cout_max = profondeur_actuelle
            end
            continue
        end

        # --- Simulation Gloutonne du chemin le plus long ---
        # On cherche combien de questions MINIMUM il faut pour séparer le pire sous-groupe
        
        # Questions disponibles (non encore posées dans cette branche)
        questions_dispo = setdiff(1:nb_total_questions, feuille["questions_posees"])
        
        depth_added = 0
        current_cluster_size = length(especes)

        # On simule tant qu'il reste plus d'une espèce ensemble
        while current_cluster_size > 1
            
            best_worst_case_size = current_cluster_size # Le mieux qu'on puisse faire pour le pire cas
            best_q = -1

            # On teste toutes les questions disponibles pour trouver la "meilleure" (celle qui casse le mieux le cluster)
            for q in questions_dispo
                reponses_possibles = vect_question_carac[q]
                
                # Taille max des sous-groupes créés par cette question
                max_subgroup_size = 0
                
                for rep_id in reponses_possibles
                    # Compter combien d'espèces tombent dans cette réponse
                    count = 0
                    for sp_id in especes
                        if df_caract_species[sp_id, rep_id]
                            count += 1
                        end
                    end
                    
                    if count > max_subgroup_size
                        max_subgroup_size = count
                    end
                end

                # Si cette question sépare mieux le groupe (réduit la taille max), on la garde
                # Note: une question utile doit réduire la taille du groupe (max_subgroup_size < current_cluster_size)
                if max_subgroup_size < best_worst_case_size && max_subgroup_size < current_cluster_size
                    best_worst_case_size = max_subgroup_size
                    best_q = q
                end
            end

            # Si on n'a trouvé aucune question capable de séparer le groupe actuel
            if best_q == -1
                # On ne peut plus séparer ces espèces (doublons ou manque de données)
                # On arrête la simulation ici. Dans un contexte strict, ce serait un coût infini,
                # mais pour l'algo on considère qu'on a atteint la limite.
                break
            end

            # On "joue" la meilleure question : on se place dans le pire cas (le plus gros paquet reste)
            current_cluster_size = best_worst_case_size
            
            # On retire la question jouée des dispos (sur ce chemin fictif)
            questions_dispo = setdiff(questions_dispo, [best_q])
            
            depth_added += 1
        end

        cout_total = profondeur_actuelle + depth_added
        
        if cout_total > cout_max
            cout_max = cout_total
        end
    end

    return cout_max
end