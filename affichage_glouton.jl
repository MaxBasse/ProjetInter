using Graphs
using GraphPlot
using JSON
using Compose # simplifier la création de graphiques complexes et sert de base au package de visualisation de données
using Cairo # dessiner des graphiques vectoriels en SVG et PDF
using Fontconfig

include("questions_parser.jl")
include("data_parsing.jl")
include("fonctions_annexes.jl")
include("glouton.jl")

"""
Construit un graphe orienté à partir de la structure issue de l’algo glouton.
Chaque "question" devient un nœud, et chaque lien "branches" devient une arête.
"""
function construire_arbre_glouton(donnees)
    g = SimpleDiGraph()
    dico_question = Dict{Int, String}()

    # Parcours des branches racines
    for (k, branche) in donnees["branches"]
        construire_sous_arbre!(g, dico_question, branche)
    end

    return g, dico_question
end


"""
Fonction récursive : ajoute les nœuds et arêtes de l’arbre glouton.
"""
function construire_sous_arbre!(g, dico_question, noeud, parent=nothing)
    if haskey(noeud, "question")
        # Ajouter la question courante comme sommet
        add_vertex!(g)
        id_q = nv(g)
        dico_question[id_q] = "Q" * string(noeud["question"])

        # Relier au parent si présent
        if parent !== nothing
            add_edge!(g, parent, id_q)
        end

        # Si ce nœud a des sous-branches, on les explore récursivement
        if haskey(noeud, "branches")
            for (k, sousbranche) in noeud["branches"]
                construire_sous_arbre!(g, dico_question, sousbranche, id_q)
            end
        end

        # S’il a des "species", on peut les afficher aussi (feuilles)
        if haskey(noeud, "species")
            for specie in noeud["species"]
                add_vertex!(g)
                id_s = nv(g)
                dico_question[id_s] = "S" * string(specie)
                add_edge!(g, id_q, id_s)
            end
        end
    end
end


"""
Affiche et sauvegarde l’arbre final produit par l’algo glouton.
"""
function afficher_arbre_glouton(donnees)
    g, dico = construire_arbre_glouton(donnees)

    labels = [dico[i] for i in 1:nv(g)]
    p = gplot(g, nodelabel=labels, nodelabeldist=1.5)

    # Affichage à l’écran (optionnel)
    display(p)

    # Sauvegarde en PDF
    draw(PDF("arbre_glouton.pdf", 30cm, 60cm), p)
end

# Lecture du fichier JSON
file = JSON.parsefile("arbre.json")
afficher_arbre_glouton(file)
