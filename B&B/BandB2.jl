include("GloutonPartiel.jl")
include("../Glouton/glouton.jl")
include("separation.jl")
include("Evaluation.jl")

function Branch_and_Bound(Qa_initial, E_initial, df_caract_species, question_unlock, questions_answers)

    # 1. Initialisation ... (Keep your existing initialization code)
    sol_glouton = glouglouton(df_caract_species, E_initial, Qa_initial, questions_answers, question_unlock)
    borne_sup = profondeur_arbre(sol_glouton)
    meilleure_solution = sol_glouton
    
    # Initialize root with a calculated bound
    racine = Noeud(
        Dict(
            "profondeur" => 0,
            "questions_accessibles" => copy(Qa_initial),
            "questions_posees" => Int[],
            "especes_restantes" => copy(E_initial),
        ), 
        0
    )
    # Calculate root bound immediately
    racine.borne_inf = evaluation(racine, df_caract_species, questions_answers)
    ListeNoeuds = [racine]

    compteur = 0
    
    # 2. Boucle principale
    while !isempty(ListeNoeuds)
        compteur += 1
        
        # STRATEGY CHANGE: Best-First Search
        # Sort so that the node with the SMALLEST lower bound is at the end (for pop!)
        sort!(ListeNoeuds, by = x -> x.borne_inf, rev = true)
        
        noeud = pop!(ListeNoeuds)

        # Pruning check (Elagage)
        if noeud.borne_inf >= borne_sup
            continue # Skip this node, it's already worse than our best solution
        end

        # Test if total key
        if Est_une_cle_determination_totale(noeud)
            cout_solution = profondeur_arbre(noeud.cle_partielle)
            if cout_solution < borne_sup
                borne_sup = cout_solution
                meilleure_solution = noeud.cle_partielle
                println("Nouvelle meilleure solution trouvée : Coût $borne_sup")
                
                # OPTIONAL: Aggressive pruning of the existing list based on new upper bound
                filter!(n -> n.borne_inf < borne_sup, ListeNoeuds)
            end
        else
            # 2.5 Branchement
            noeud_inter = separation(noeud, questions_answers, question_unlock, df_caract_species)
            
            # CRITICAL FIX: Evaluate children IMMEDIATELY
            noeuds_to_keep = Noeud[]
            
            for child in noeud_inter
                # Calculate Lower Bound for the child
                child.borne_inf = evaluation(child, df_caract_species, questions_answers)
                
                # Only keep the child if it has potential to beat the current Upper Bound
                if child.borne_inf < borne_sup
                    push!(noeuds_to_keep, child)
                end
            end
            
            # Add valid children to the list
            append!(ListeNoeuds, noeuds_to_keep)

            # 2.6 Glouton heuristic (Optional but good)
            # You can keep your existing glouton logic here to try and lower borne_sup further
            borne_sup_locale, sol_locale = glouton_borne_inf(noeud, df_caract_species, questions_answers, question_unlock)
            if borne_sup_locale < borne_sup
                borne_sup = borne_sup_locale
                meilleure_solution = sol_locale
                println("Glouton a trouvé une meilleure solution : Coût $borne_sup")
                filter!(n -> n.borne_inf < borne_sup, ListeNoeuds)
            end
        end
        
        # Better Logging
        if compteur % 100 == 0
             println("Iter: $compteur | Stack: $(length(ListeNoeuds)) | Best: $borne_sup | Current LB: $(noeud.borne_inf)")
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

"""
cle_totale = Dict(
    :profondeur => 0,
    :especes_restantes => [1,2,3],
    :branches => Dict(
        10 => Dict(
            :profondeur => 1,
            :especes_restantes => [1],
            :branches => Dict()
        ),
        20 => Dict(
            :profondeur => 1,
            :especes_restantes => [2],
            :branches => Dict()
        ),
        30 => Dict(
            :profondeur => 1,
            :especes_restantes => [3,1],
            :branches => Dict()
        )
    )
)

print(cle_totale_recursive(cle_totale))
"""