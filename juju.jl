using JSON

# Faire apparaître le terminal Julia
# Ctrl + Shift +P
# Taper "Julia: Start REPL" et valider avec Entrée

# Changement de répertoire de travail si nécessaire
# pwd()  # Affiche le répertoire de travail actuel
# cd("C:/Users/justi/Document_Personnel/Scolarite_etudiante/4eme_annee_INSA_Rennes/Semestre_7/Projet interdiciplinaire/Code perso")  # Change le répertoire de travail
# pwd()  # Vérifie le changement de répertoire

#########################################################################################
# Lecture du fichier JSON: file est un dictionnaire
file = JSON.parsefile("question_reponse.json")

# Création d'une liste vide pour contenir les espèces
liste_espece = []

# test d'accès aux données 
# println(file["collection"][1]["latin"])  # Affiche le nom latin de la première espèce

# Parcours de toutes les espèces du fichier JSON
for ligne in file["collection"]
    # Ajout de l'espèce à la fin de la liste des espèces
    push!(liste_espece, ligne["latin"])
end

# Affichage de la liste des espèces
# println(liste_espece)

# Affichage du nombre d'espèce 
# println(length(liste_espece))

# Test jouer pour comprendre le fichier JSON
#println(file["questions"][1]["answers"])

#########################################################################################

#####################################################################################
using Graphs
using GraphPlot

function construire_arbre_question(donnee)
    # Création d'un graphe orienté vide
    graphe=SimpleDiGraph()

    # Association d'un numéro à chaque question 
    dico_question = Dict{Int, String}()

    # Parcours uniquement des questions "racines"
    for ligne in donnee["questions"]
        # Exploration des sous questions
        ajout_question(graphe, dico_question, ligne)
    end

    # Retourne le graphe et le dictionnaire des questions
    return graphe, dico_question
    
end

function ajout_question(graphe, dico_question, ligne, num_parent=nothing)
    # Etape 1: Création d'un nouveau sommet pour la question considérée
    # Récupération de la question 
    q_a_ajouter = ligne["title_q"]
    # Ajout de la question au dictionnaire
    if !(q_a_ajouter in values(dico_question))
        # Ajout de la question en tant que nouveau sommet au graphe
        add_vertex!(graphe)
        # Récupération du numéro de la question 
        id_q=nv(graphe)
        dico_question[id_q]=q_a_ajouter
    else
        # Recherche de la (première d'où first) clé correspondant à cette question 
        id_q = first(cle for (cle,valeur) in dico_question if valeur == q_a_ajouter)
    end

    # Etape 2 (si nécessaire): Reliage du sommet de la nouvelle question au reste du graphe
    # Position de la question dans le fichier JSON ie est ce que il y a une question au dessus (ie un parent)
    if num_parent !== nothing
        # Ajout de l'arrète reliant la question parent de la question considérée
        add_edge!(graphe,num_parent,id_q)
    end

    # Etape 3: Est ce que la question est elle même parent ? 
    for reponse in ligne["answers"] # pas besoin de ["title_q"][1] car c'est sur la même ligne ie pas de [
        # Si la question a un fils on doit aussi l'ajouter au graphe
        for q_fille in reponse["unlock_questions"]
            # Récursivité pour ajouter la question fille au graphe
            ajout_question(graphe, dico_question, q_fille, id_q)
        end
    end

    # Renvoie du graphe et du dictionnaire de question mis à jour 
    return graphe, dico_question

end

# pour sauvegarder l'arbre en pdf
using Compose
using Fontconfig
using Cairo

function afficher_arbre(donnee)
    # Construction de l'arbre avec les fonctions écrites avant
    g, dico_question = construire_arbre_question(donnee)

    # Labels des sommets (questions)
    labels = [dico_question[sommet] for sommet in 1:nv(g)]
    # Affichage 
    gplot(g, nodelabel = labels, nodelabeldist=1.5) 
    
    # enregistrer l'arbre résultat en pdf 
    draw(PDF("resultat_arbre.pdf", 30cm, 60cm), gplot(g,nodelabel = labels, nodelabeldist=1.5)) 
end

# Test des fonctions
afficher_arbre(file)

# source aide: 
# https://juliagraphs.org/Graphs.jl/dev/core_functions/simplegraphs/#Graphs.SimpleGraphs.add_vertex!-Union{Tuple{SimpleGraph{T}},%20Tuple{T}}%20where%20T
# https://juliagraphs.org/GraphPlot.jl/#add-node-label
# https://app.studyraid.com/fr/read/4194/86684/dictionnaires-et-ensembles

