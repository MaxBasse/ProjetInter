"""
Evaluation pour déterminer une borne inf sur le coût d'une clé de détermination
Le coût sera une métrique choisie telle que le nombre de questions posées, la profondeur maximale, etc...
"""
function evaluation(noeud::Noeud)
    # Récupération des feuilles de la clé partielle
    cle_partielle = noeud.cle_partielle
    feuille_iterator = Leaves(cle_partielle.racine)
    
    cout_total = 0
    for feuille in feuille_iterator
        if feuille.eval == nothing continue end
        cout_feuille = feuille.rang  

        remaining_q = setdiff(1:length(vect_question), feuille.questions_posees)
        nombre_especes = length(feuille.especes)

        nb_reponses_possibles = [length(vect_question_carac[q]) for q in remaining_q]
        
        if !isempty(nb_reponses_possibles)
            sort!(nb_reponses_possibles, rev=true)
            cumprod!(nb_reponses_possibles)
            idx = findfirst(x -> x >= nombre_especes, nb_reponses_possibles)
            if idx !== nothing
                cout_feuille += idx
            end
        end
        
        cout_total = max(cout_total, cout_feuille)
    end
    return cout_total
end