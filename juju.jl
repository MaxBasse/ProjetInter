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

Etape 2: Je sélectionne les questions candidates 
- soit avec le critère maximiser la profondeur de la branche ie max |S2| |S1|
- soit avec le critère maximiser la largeur de la branche ie min |S1| |S2|
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

function branch_and_bound_juju(especes_non_identifiees, caracteristiques_restantes, graphe, matrice ,best_borne_inf, liste_questions_posees)
    # Choix de la prochaine question 
    #question = meilleure_question() à coder

    # Cas où il ne reste plus qu'une espèce 
    if (length(especes_non_identifiees)==1)
        add_vertex!(graphe)
        add_edge!(graphe, nv(graphe)-1, nv(graphe))
        return especes_non_identifiees, graphe
    end

    # Cas où il n'y a plus de question à poser: cela signifie que on a pas pu identifier une espèce en particulier
    if (length(question_restante)==0)
        return especes_non_identifiees
    end
    # Initialisation de la meilleure question
    meilleure_caracteristique= None

    for carac in caracteristiques_restantes 
        compteur_oui=0
        compteur_non=0
        for espece in especes_non_identifiees
            if (matrice[espece, carac]==1)
                compteur_oui=compteur_oui+1
            else
                compteur_non=compteur_non+1
            end
        end
        # Equivalent à compteur_oui=[espece for ]
    end

    # Sélection de la meilleure caractéristique à
    #=

    best_split_value = float('inf')

    # Sélection de la meilleure question à poser
    for q in questions_restantes:
        # Partitionne les espèces selon la réponse oui/non à la question q
        S_yes = [i for i in S if M[i][q] == 1]
        S_no  = [i for i in S if M[i][q] == 0]

        # Critère de sélection du "meilleur" découpage
        # Par ex : minimiser le déséquilibre des groupes => max(|S_yes| * |S_no|)
        split_value = abs(len(S_yes) - len(S_no))  # ou autre critère

        if split_value < best_split_value:
            best_split_value = split_value
            best_question = q

    # On pose la question "best_question" 
    reponse = poser_question(best_question)

    # On explore uniquement la branche cohérente avec la réponse donnée
    if reponse == "oui":
        S_next = [i for i in S if M[i][best_question] == 1]
    else:
        S_next = [i for i in S if M[i][best_question] == 0]

    # On met à jour l’ensemble des questions restantes
    next_questions = [q for q in questions_restantes if q != best_question]

    # Récursion : on continue dans la bonne branche
    return branch_and_bound(S_next, next_questions)

    =#

end


def entropy(subset):
    # Ici chaque espèce est unique, donc entropie max = log2(len(subset))
    if len(subset) <= 1:
        return 0
    return math.log2(len(subset))


def info_gain(matrix, species_subset, feature_index):
    # Séparer selon la question
    yes = [i for i in species_subset if matrix[i][feature_index] == 1]
    no = [i for i in species_subset if matrix[i][feature_index] == 0]

    total = len(species_subset)
    H_before = entropy(species_subset)
    H_after = (len(yes)/total)*entropy(yes) + (len(no)/total)*entropy(no)
    return H_before - H_after

def best_question(matrix, species_subset):
    n_features = len(matrix[0])
    gains = [info_gain(matrix, species_subset, j) for j in range(n_features)]
    return int(np.argmax(gains)), max(gains)



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





