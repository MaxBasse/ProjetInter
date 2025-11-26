using JSON
using FileIO
using GraphViz

"""
    extract_styled_elements!(node, parent_id, branch_label, nodes, edges, node_counter)

Parcourt l'arbre et extrait les informations en appliquant un style 
spécifique pour une clé de détermination botanique.
"""
function extract_styled_elements!(node, parent_id, branch_label, nodes, edges, node_counter)
    # 1. Générer un ID unique
    current_node_id = "N$(node_counter[1])"
    node_counter[1] += 1

    # 2. Déterminer le Label et le Style (Attributs Graphviz)
    label = ""
    attributes = ""

    if haskey(node, "question")
        # Nœud de décision (Question)
        q_num = node["question"]
        label = "Question $(q_num)"
        # Style : Boîte bleue clair
        attributes = "shape=box, style=\"filled\", fillcolor=\"lightblue\""
        
    elseif haskey(node, "species")
        # Nœud terminal (Espèce)
        # On joint la liste des espèces par des virgules
        s_list = join(string.(node["species"]), ", ")
        label = "Espèce(s): $(s_list)"
        # Style : Ellipse verte clair (pour le côté botanique)
        attributes = "shape=ellipse, style=\"filled\", fillcolor=\"lightgreen\""
        
    elseif haskey(node, "especes")
        # Nœud terminal (Espèce)
        # On joint la liste des espèces par des virgules
        s_list = join(string.(node["especes"]), ", ")
        label = "Espèce(s): $(s_list)"
        # Style : Ellipse verte clair (pour le côté botanique)
        attributes = "shape=ellipse, style=\"filled\", fillcolor=\"lightgreen\""
        
    else
        
        # Racine ou autre (si pas de question explicite au début)
        label = "Début"
        attributes = "shape=diamond, style=\"filled\", fillcolor=\"gold\""
    end

    # Stocker le nœud avec ses attributs
    push!(nodes, (current_node_id, label, attributes))

    # 3. Créer l'arête (Lien) depuis le parent
    if !isnothing(parent_id)
        # branch_label est la réponse à la question précédente
        push!(edges, (parent_id, current_node_id, branch_label))
    end

    # 4. Récursion sur les branches
    if haskey(node, "branches")
        # Trier les clés pour un ordre visuel cohérent (optionnel mais recommandé)
        sorted_keys = sort(collect(keys(node["branches"])))
        
        for key in sorted_keys
            child_node = node["branches"][key]
            extract_styled_elements!(
                child_node, 
                current_node_id, 
                key, 
                nodes, 
                edges, 
                node_counter
            )
        end
    end
end

function generate_botanic_dot(json_path::String, dot_output_path::String)
    # Charger le JSON
    data = open(json_path, "r") do f
        JSON.parse(f)
    end

    nodes = [] # Tuples: (id, label, attributes)
    edges = [] # Tuples: (source, target, label)
    node_counter = [0]

    # Lancer l'extraction
    extract_styled_elements!(data, nothing, nothing, nodes, edges, node_counter)

    # Écriture du fichier DOT
    open(dot_output_path, "w") do f
        write(f, "digraph BotanicKey {\n")
        
        # Paramètres globaux pour améliorer la lisibilité
        write(f, "  node [fontname=\"Arial\"];\n")
        write(f, "  edge [fontname=\"Arial\", fontsize=10];\n\n")
        write(f, "  layout=dot;\n")       # Force l'algo hiérarchique (CRUCIAL)
        write(f, "  rankdir=LR;\n")       # Orientation Gauche -> Droite (plus lisible pour votre arbre)    
        write(f, "  overlap=false;\n")     # Interdire strictement le chevauchement

        # Écriture des Nœuds
        for (id, lbl, attr) in nodes
            # Échapper les guillemets dans les labels
            safe_lbl = replace(lbl, "\"" => "\\\"")
            write(f, "  $(id) [label=\"$(safe_lbl)\", $(attr)];\n")
        end

        write(f, "\n")

        # Écriture des Arêtes
        for (src, dst, lbl) in edges
            safe_lbl = replace(string(lbl), "\"" => "\\\"")
            write(f, "  $(src) -> $(dst) [label=\"$(safe_lbl)\"];\n")
        end

        write(f, "}\n")
    end

    println("Fichier généré : $(dot_output_path)")
    println("Nombre de nœuds : $(length(nodes))")
end

function generate_botanic_svg(json_path::String, dot_path::String, svg_path::String)

    generate_botanic_dot(json_path, dot_path)

    contenu_dot = read(dot_path, String)
    g = GraphViz.Graph(contenu_dot)

    GraphViz.layout!(g, engine="dot")

    open(svg_path, "w") do f
        GraphViz.render(f, g)
    end
end

generate_botanic_svg("arbre_simplifie_grand.json", "arbre_simplifie_grand.dot", "arbre_simplifie_grand.svg")
