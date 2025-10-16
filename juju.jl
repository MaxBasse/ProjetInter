using JSON

# Faire apparaître le terminal Julia
# Ctrl + Shift +P
# Taper "Julia: Start REPL" et valider avec Entrée

# Changement de répertoire de travail si nécessaire
# pwd()  # Affiche le répertoire de travail actuel
# cd("C:/Users/justi/Document_Personnel/Scolarite_etudiante/4eme_annee_INSA_Rennes/Semestre_7/Projet interdiciplinaire/Code perso")  # Change le répertoire de travail
# pwd()  # Vérifie le changement de répertoire

#########################################################################################
#=
Chaque noeud de l'arbre correspond à une question 
- si la réponse à la question est "oui" (dans le sens où l'espèce possède la caractéristique) alors je descends à gauche
- si la réponse à la question est "non" alors je descends à droite
Le but est de trouver l'ordre des questions à poser afin de distinguer toutes les espèces avec le moins de questions possibles.

BRANCH: exploration / ébaloration d'arbre
Etape 1: J'ai besoin de à l'instant t: 
-> la liste des espèces disponibles (especes_non_identifiees)
-> la liste des questions pas encore posées (question_restante /accessibles)
-> du graphe construit jusqu'à l'instant t (graphe)
-> la meilleure borne connue à l'instant t (best_borne_inf)

Etape 2: Je sélectionne une question candidate 
- soit avec le critère
- soit avec le critère 
La question divise la liste des espèces en deux groupes:
- groupe possédant la caractéristique
- groupe ne possédant pas la caractéristique

Etape 3: AVANT DE CONTINUER =>BOUND
Avant de descendre plus en profondeur dans la branche du groupe possédant la caractéristique, il faut calculer une borne inférieure. 
Etape 3.1: Borne à définir: 
exemple de borne inférieur: s'il reste k espèces non distinguer il faudra au moins log2 (k) questions pour pouvoir les séparer complémentement. 
Etape 3.2: Comparaison à la meilleure solution connue
il faut comparer la borne inférieur calculée avec la meilleure solution qu'on possède à l'instant t 
=> Si la borne calculée est pire que la meilleure solution connue alors on coupe la branche car on ne fera pas mieux dans la suite de la branche
=> Si la borne calculée est meilleure que la meilleure solution connue alors notre borne devient la nouvelle meilleure solution connue et on continue ainsi l'exploration de la branche

Etape 4: Il faut ensuite répéter ce processus sur chaque sous groupe non éliminé
=#
include("fonctions_annexes.jl")

function branch_and_bound_juju(especes_non_identifiees, question_restante, graphe, best_borne_inf)
    # Choix de la prochaine question 
    #question = meilleure_question() à coder
    

end




#########################################################################################
using Graphs
using GraphPlot

G = DiGraph()  # un graphe orienté (chaque branche = direction)
add_vertex!(G)  # noeud racine
add_vertex!(G)
add_vertex!(G)

# exemple : ajout d'une question et de ses deux réponses
add_edge!(G, 1, 2)  # 1 => "Oui"
add_edge!(G, 1, 3)  # 1 => "Non"
gplot(G)

function branch_and_bound(species_matrix, remaining_species, remaining_questions, G, node_id)
    # Cas de base : si 1 seule espèce => feuille
    if length(remaining_species) == 1
        return
    end

    # Sélectionne la "meilleure" question à poser
    q = select_best_question(species_matrix, remaining_species, remaining_questions)

    # Crée les sous-groupes selon la réponse
    for value in [0, 1]
        subset = filter(spec -> species_matrix[spec, q] == value, remaining_species)

        if !isempty(subset)
            new_node = nv(G) + 1
            add_vertex!(G)
            add_edge!(G, node_id, new_node)
            branch_and_bound(species_matrix, subset, setdiff(remaining_questions, [q]), G, new_node)
        end
    end
end





