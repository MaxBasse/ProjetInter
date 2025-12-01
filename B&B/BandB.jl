include("GloutonPartiel.jl")
include("separation2.jl")
include("Evaluation.jl")

"""
     Branch_and_Bound(Qa_initial, E_initial, df_caract_species, question_unlock, questions_answers)

Algorithme de Branch and Bound pour la construction d'une clé de détermination optimale.
# Arguments
- `Qa_initial::Vector{Int}` : Liste des questions accessibles initiales.
- `E_initial::Vector{Int}` : Liste des espèces restantes initiales.
- `df_caract_species::BitMatrix` : Matrice binaire contenant les caractéristiques des espèces.
- `question_unlock::Dict{Int, Vector{Int}}` : Dictionnaire des questions débloquées par chaque question.
- `questions_answers::Dict{Int, Vector{Int}}` : Dictionnaire des réponses possibles pour chaque question.

# Returns
- `meilleure_solution::Dict` : La clé de détermination optimale trouvée.
- `borne_sup::Int` : Le coût (profondeur) de la meilleure solution trouvée.

# Exemple
    Qa_initial = [1, 2, 3, 4, 5]
    E_initial = [1, 2, 3, 4, 5, 6]
    df_caract_species = BitMatrix(...) # Matrice binaire des caractéristiques des espèces
    question_unlock = Dict(1 => [2, 3], 2 => [4], ...)
    questions_answers = Dict(1 => [10, 20], 2 => [30, 40], ...)

    meilleure_solution, borne_sup = Branch_and_Bound(Qa_initial, E_initial, df_caract_species, question_unlock, questions_answers)
"""
function Branch_and_Bound(Qa_initial::Vector{Int}, E_initial::Vector{Int}, df_caract_species::BitMatrix, question_unlock::Vector{Vector{Int64}}, questions_answers::Vector{Vector{Int64}})
 
    # 1. Initialisation du noeud racine et des variables B&B 
      
    sol_glouton = glouglouton(df_caract_species, copy(E_initial), copy(Qa_initial), questions_answers, question_unlock)

    # Calcul initial de la borne supérieure via le glouton
    borne_sup = profondeur_arbre(sol_glouton)
    meilleure_solution = sol_glouton
    racine = Noeud(
        Dict(
        "profondeur" => 0,
        "questions_accessibles" => copy(Qa_initial),
        "questions_posees" => Int[],
        "especes_restantes" => copy(E_initial),
        #"question" => -1,
        #"branches" => Dict{Int, Any}()
    ), 
        0
    )
    
    # Liste des noeuds à explorer, soit une file pour largeur soit une pile pour profondeur
    ListeNoeuds = [racine]
     
    # 2. Boucle principale du B&B     
    compteur=0
    while !isempty(ListeNoeuds)
        println(compteur)
        compteur+=1
    
        # 2.1 Sélection d’un noeud selon une stratégie (profondeur, largeur ?) 
        if compteur % 50 == 0
            sort!(ListeNoeuds, by = n -> n.borne_inf, rev=true)         
        end
        if compteur % 200 == 0
            sort!(ListeNoeuds, by = n -> n.borne_inf, rev=false)
        end
        
        noeud = pop!(ListeNoeuds)  

        # 2.2 Calcul de la borne inférieure   #

        borne_inf = evaluation(noeud, length(questions_answers), questions_answers)
          
        # 2.3 Test afin de savoir si on peut élaguer tels des bucherons gaziers
        if borne_inf >= borne_sup
            # badaboum on élague (en gros on fait R)
            #println("élagage de fifou")
            continue
        end

        # 2.4 Test si la clé partielle s'avère plutot etre une clé totalement définie (chaque feuille est vide ou une espece) #  
        if Est_une_cle_determination_totale(noeud)

            cout_solution = profondeur_arbre(noeud.cle_partielle)
            # Mise à jour de la borne supérieure si amélioration
            if cout_solution < borne_sup
                borne_sup = cout_solution
                meilleure_solution = noeud.cle_partielle
            end

        else
            
               
            # 2.5 Branchement : création des noeuds fils          #  
            noeud_inter=separation(noeud, questions_answers, question_unlock, df_caract_species)
            noeuds_to_keep = Noeud[]

            for child in noeud_inter
                # Calculate Lower Bound for the child
                child.borne_inf = evaluation(noeud, length(questions_answers), questions_answers)
                
                # Only keep the child if it has potential to beat the current Upper Bound
                if child.borne_inf < borne_sup
                    push!(noeuds_to_keep, child)
                end
            end
            
            # Add valid children to the list
            append!(ListeNoeuds, noeuds_to_keep)
            
            if compteur % 100 == 0
                @info "Itération $compteur : Borne inférieure = $(noeud.borne_inf), Borne supérieure = $borne_sup, Taille de la liste des noeuds = $(length(ListeNoeuds))"            
                # 2.6 Mise à jour de la borne sup via glouton sur clé partielle (pas sur de MAJ a chaque fois mais on laisse comme cela pour l'instant)
                borne_sup_locale, sol_locale = glouton_borne_inf(deepcopy(noeud), df_caract_species, questions_answers, question_unlock)
                
                if borne_sup_locale < borne_sup
                    borne_sup = borne_sup_locale
                    meilleure_solution = sol_locale
                    println("Glouton a trouvé une meilleure solution : Coût $borne_sup")
                    filter!(n -> n.borne_inf <= borne_sup, ListeNoeuds)
                end
            end
        end
        # Fin du traitement du noeud -> il est sorti de la liste via selection_noeud!
        #println("Iter: $compteur | Stack: $(length(ListeNoeuds)) | Best: $borne_sup | Current LB: $(noeud.borne_inf)")
    end


    
    return meilleure_solution, borne_sup
end

"""
    Est_une_cle_determination_totale(noeud::Noeud)::Bool

Vérifie si la clé partielle contenue dans le noeud correspond à une clé de détermination totale,
c'est-à-dire si chaque feuille de la clé mène à une espèce unique ou est vide. 
Utilise la fonction récursive `cle_totale_recursive`.

# Arguments
- `noeud::Noeud` : Le noeud contenant la clé partielle à vérifier.

# Returns
- `Bool` : Retourne `true` si la clé est totale, `false` sinon.

# Exemple
    noeud = Noeud(cle, 0)
    print(Est_une_cle_determination_totale(noeud)) # Affiche false
"""
function Est_une_cle_determination_totale(noeud::Noeud)::Bool
    return cle_totale_recursive(noeud.cle_partielle)
end

"""
    cle_totale_recursive(cle::Dict{Any,Any})::Bool

Vérifie récursivement si une clé de détermination est totale,
c'est-à-dire si chaque feuille de la clé mène à une espèce unique ou est vide.

# Arguments
- `cle::Dict{Any,Any}` : La clé de détermination représentée sous forme de dictionnaire.

# Returns
- `Bool` : Retourne `true` si la clé est totale, `false` sinon.
"""
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