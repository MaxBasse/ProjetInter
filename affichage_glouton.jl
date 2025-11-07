using Graphs
using GraphPlot
using JSON
using Compose # simplifier la création de graphiques complexes et sert de base au package de visualisation de données
using Cairo # dessiner des graphiques vectoriels en SVG et PDF
using Fontconfig
using GraphViz

include("questions_parser.jl")
include("data_parsing.jl")
include("fonctions_annexes.jl")
include("glouton.jl")

#########################################################################################
# Mon mapping pour la visualisation du graphe du généré avec le glouton 

# Dictionnaire question_id -> texte
map_questions = Dict{Int, String}()
for (i, q) in enumerate(vect_question) # vect_question est dans questions_parser pour rappel c'est une liste avec les questions contenuent dans data.json
    map_questions[i] = q # i est l'identifiant associé à la question q
end

# Dictionnaire question_id -> réponses possibles
map_answers = Dict{Int, Dict{String, String}}()
# i correspond à l'indice de la question considérée
# reponse est le vecteur des réponses associées à la question 
for (i, reponse) in enumerate(vect_question_carac) # vect_question_carac est dans questions_parser pour rappel cela liste pour chaque question, la liste des caractéristiques associées
    rep_dict = Dict{String, String}()
    for r in reponse # parcours de toutes les réponses possibles à la question i
        rep_dict[string(r)] = string(r) 
    end
    map_answers[i] = rep_dict # map_answers est un dictionnaire de dictionnaires
end

# Dictionnaire espèce_id -> nom 
map_species = Dict{Int, String}() # on crée un équivalent de map_questions mais pour les espèces
for (i, nom) in enumerate(vect_species) # vect_species est dans data_parsing
    map_species[i] = nom
end

#########################################################################################
"""
Construit récursivement le graphe à partir de la structure de l’arbre glouton.
"""
function construire_sous_arbre_glouton!(
    g::SimpleDiGraph,
    labels::Dict{Int,String},
    node::Dict;
    parent::Union{Int,Nothing}=nothing,
    map_questions=Dict(),
    map_answers=Dict(),
    map_species=Dict(),
)
    # 1Ajouter la question (si présente)
    current = nothing
    if haskey(node, "question")
        qid = node["question"]
        qtext = get(map_questions, qid, "Question $qid")
        add_vertex!(g)
        current = nv(g)
        labels[current] = "❓ " * qtext

        # relier au parent
        if parent !== nothing
            add_edge!(g, parent, current)
        end

    elseif parent === nothing
        # Si racine sans "question"
        add_vertex!(g)
        current = nv(g)
        labels[current] = "(racine)"
    end

    # Ajouter les branches (réponses possibles)
    if haskey(node, "branches")
        for (key, child) in node["branches"]
            # trouver le libellé de la réponse
            qid = get(node, "question", nothing)
            answer_label = qid === nothing ? string(key) :
                get(get(map_answers, qid, Dict()), string(key), string(key))

            add_vertex!(g)
            child_id = nv(g)
            labels[child_id] = "💬 " * answer_label
            if current !== nothing
                add_edge!(g, current, child_id)
            end

            # exploration récursive
            construire_sous_arbre_glouton!(g, labels, child;
                parent=child_id,
                map_questions=map_questions,
                map_answers=map_answers,
                map_species=map_species)
        end
    end

    # Ajouter les espèces (feuilles)
    if haskey(node, "species")
        for s in node["species"]
            add_vertex!(g)
            sid = nv(g)
            labels[sid] = "🌿 " * get(map_species, s, "Espèce $s")
            if current !== nothing
                add_edge!(g, current, sid)
            end
        end
    end

    return g, labels
end


"""
Construit et affiche le graphe de l'arbre glouton avec libellés.
"""
function afficher_arbre_glouton(file::Dict,
                                map_questions::Dict,
                                map_answers::Dict,
                                map_species::Dict)
    println("🔧 Construction de l’arbre glouton...")

    g = SimpleDiGraph()
    labels = Dict{Int,String}()

    construire_sous_arbre_glouton!(g, labels, file;
        map_questions=map_questions,
        map_answers=map_answers,
        map_species=map_species)

    println("✅ Arbre construit avec $(nv(g)) nœuds et $(ne(g)) arêtes.")

    # labels à afficher
    node_labels = [labels[i] for i in 1:nv(g)]

    # Graphique interactif + PDF
    p = gplot(g, nodelabel=node_labels, nodelabeldist=1.5, nodesize=0.3, arrowlengthfrac=0.05)
    display(p)

    # Export PDF
    draw(PDF("arbre_glouton_graphique.pdf", 40cm, 80cm), p)
    println("📄 PDF généré : arbre_glouton_graphique.pdf")
end

# Test
arbre = JSON.parsefile("arbre.json")
afficher_arbre_glouton(arbre, map_questions, map_answers, map_species)


###########################################################################################
function save_tree_graphviz(file::Dict, map_questions, map_answers, map_species; outpath="arbre_glouton_graphviz.pdf")
    g = SimpleDiGraph()

    function rec(node, parent_name=nothing)
        label = ""
        if haskey(node, "question")
            qid = node["question"]
            label = "❓ " * get(map_questions, qid, "Question $qid")
        elseif haskey(node, "species")
            label = "🌿 " * join([get(map_species, s, "Espèce $s") for s in node["species"]], ", ")
        else
            label = "(racine)"
        end

        current = add_node!(g, gensym("n"), label=label, shape="box", style="rounded,filled", fillcolor="lightyellow")

        if parent_name !== nothing
            add_edge!(g, parent_name, current)
        end

        if haskey(node, "branches")
            for (ans, sub) in node["branches"]
                answer_label = haskey(node, "question") ?
                    get(get(map_answers, node["question"], Dict()), string(ans), string(ans)) :
                    string(ans)
                child_label = "💬 " * answer_label
                edge_node = add_node!(g, gensym("a"), label=child_label, shape="ellipse", style="filled", fillcolor="lightblue")
                add_edge!(g, current, edge_node)
                rec(sub, edge_node)
            end
        end
    end

    rec(file)

    save(g, outpath)
    println("✅ Graphe hiérarchique exporté : $outpath")
end


arbre = JSON.parsefile("arbre.json")
save_tree_graphviz(arbre, map_questions, map_answers, map_species)


