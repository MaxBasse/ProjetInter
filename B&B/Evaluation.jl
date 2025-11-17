"""
Evaluation pour déterminer une borne inf sur le coût d'une clé de détermination
Le coût sera une métrique choisie telle que le nombre de questions posées, la profondeur maximale, etc...
"""
function evaluation(Noeud::n)
    # Récupération des feuilles de la clé partielle
    cle_partielle = n.cle_partielle
    feuille_iterator = Leaves(cle_partielle.racine)
    cout_max = 0

    for feuille in feuille_iterator
        if feuille.eval == null continue end

        #setdiff
        remaining_q = setdiff((1:length(vect_question)), feuille.questions_posees)

        nombre_especes = length(feuille.especes)

        nb_reponses_possibles = [length(vect_question_carac[q]) for q in remaining_q]
        
        sort!(nb_reponses_possibles, rev=true)
        cumprod!(nb_reponses_possibles)
        cout_feuille = feuille.rang + findfirst(x -> x >= nombre_especes, nb_reponses_possibles)
        if cout_feuille > cout_max
            cout_max = cout_feuille
        end
    end
    return 0
end