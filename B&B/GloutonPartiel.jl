"""
L'idée pour recalculer une possible meilleure borne d'élagage avec un glouton à partir d'une clé partielle :

feuilles = toutes les feuilles de la clé_partielle

pour chaque feuille f : On la remplace par son glouton
    arbre_glouton = glouglouton(... pour cette feuille ...)
    remplacer_feuille(cle, feuille, arbre_glouton)

calculer la profondeur max sur l'arbre total
profondeur_max = profondeur_arbre(cle)

si profondeur_max < borne_sup :
    borne_sup = profondeur_max
    meilleure_solution = clé partielle complétée avec les gloutons

"""
include("../Glouton/glouton.jl")


# Etape 1 : On récupère toutes les feuilles d'une clé partielle pour réaliser un glouton sur chacune d'entre elles

function feuilles_cle_partielle(noeud::Dict, profondeur::Int=0, liste_feuilles::Vector{Tuple{Dict,Int}} = Vector{Tuple{Dict,Int}}())
    if haskey(noeud, "branches") && !isempty(noeud["branches"])
        for (_,fils) in noeud["branches"]
            feuilles_cle_partielle(fils, profondeur + 1, liste_feuilles)
        end
    else
        push!(liste_feuilles, (noeud, profondeur))
    end
    return liste_feuilles
end


# Etape 2 : On calcul la profondeur de notre arbre généré (DFS)

function profondeur_arbre(arbre::Dict)
    if !haskey(arbre, "branches") || isempty(arbre["branches"])
        return 0
    end
    max_prof = 0
    for (_,fils) in arbre["branches"]
        max_prof = max(max_prof, 1 + profondeur_arbre(fils))
    end
    return max_prof
end

# Etape 3 : Remplacer la feuille par son glouton dans une copie profonde de la clé partielle.

function remplacer_feuille(noeud::Dict, feuille::Dict, arbre_glouton_f::Dict)
    if noeud === feuille
        empty!(noeud)
        merge!(noeud, arbre_glouton_f)
        return true
    end

    if haskey(noeud, "branches")
        for (rep, fils) in noeud["branches"]
            if remplacer_feuille(fils, feuille, arbre_glouton_f)
                return true
            end
        end
    end

    return false
end    



# Etape 4 : Fonction principale appelée par le B&B

function glouton_borne_inf(noeud::Noeud, df_caract_species::BitMatrix, questions_answers::Vector{Vector{Int}}, question_unlock::Vector{Vector{Int}})

    # Copie profonde de la clé partielle
    cle = deepcopy(noeud.cle_partielle)

    # Récupération de toutes les feuilles
    feuilles = feuilles_cle_partielle(cle)

    # Remplacement de chaque feuille par son glouton
    for feuille in feuilles
        remaining   = feuille["especes_restantes"]
        accessibles = feuille["questions_accessibles"]
        posees      = feuille["questions_posees"]

        arbre_glouton = glouglouton(df_caract_species, remaining, accessibles, questions_answers, question_unlock, posees)

        remplacer_feuille(cle, feuille, arbre_glouton)
    end

    # Profondeur max de l'arbre complet
    profondeur_max = profondeur_arbre(cle)

    return profondeur_max, cle
end


