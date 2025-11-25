using JSON

"""
    extract_graph_elements!(node, parent_id, branch_label, nodes, edges, node_counter)

Fonction récursive pour parcourir la structure JSON de l'arbre et extraire les nœuds
et les arêtes au format Graphviz DOT.

- `nodes` et `edges` sont mutés et remplis par la fonction.
- `node_counter` est utilisé pour générer des identifiants uniques de nœuds.
"""
function extract_graph_elements!(node, parent_id, branch_label, nodes, edges, node_counter)
    # Assignation d'un ID unique au nœud courant
    current_node_id = "N$(node_counter[1])"
    node_counter[1] += 1

    # Déterminer l'étiquette du nœud
    if haskey(node, "question")
        label = "Question $(node["question"])"
    elseif haskey(node, "species")
        species_list = join(string.(node["species"]), ", ")
        label = "Espèces: $(species_list)"
    else
        label = "Root" # Cas du nœud racine initial
    end

    push!(nodes, (current_node_id, label))

    # Créer une arête à partir du parent vers le nœud courant
    if !isnothing(parent_id)
        push!(edges, (parent_id, current_node_id, branch_label))
    end

    # Récurrence sur les branches
    if haskey(node, "branches")
        for (branch_key, sub_node) in node["branches"]
            extract_graph_elements!(
                sub_node,
                current_node_id,
                branch_key,
                nodes,
                edges,
                node_counter
            )
        end
    end
    return nothing
end

function generate_dot_file(file_path::String, output_filename::String)
    # 1. Charger le fichier JSON
    data = open(file_path) do f
        JSON.parse(f)
    end

    # Initialisation des structures de données
    nodes = [] # (node_id, label)
    edges = [] # (source, target, label)
    node_counter = [0] # Compteur mutable pour les IDs de nœuds

    # 2. Parcourir l'arbre
    extract_graph_elements!(data, nothing, nothing, nodes, edges, node_counter)

    # 3. Générer le contenu DOT
    dot_output = "digraph DecisionTree {\n"
    dot_output *= "  node [shape=box];\n\n"

    # Définir les nœuds
    for (node_id, label) in nodes
        # Échapper les guillemets pour le format DOT
        escaped_label = replace(label, "\"" => "\\\"")
        dot_output *= "  $(node_id) [label=\"$(escaped_label)\"];\n"
    end

    dot_output *= "\n"

    # Définir les arêtes
    for (source, target, label) in edges
        dot_output *= "  $(source) -> $(target) [label=\"$(label)\"];\n"
    end

    dot_output *= "}\n"

    # 4. Écrire le fichier DOT
    open(output_filename, "w") do f
        write(f, dot_output)
    end

    println("Fichier DOT généré avec succès : $(output_filename)")
end

# --- Exécution ---
# Remplacez 'arbre.json' par le chemin de votre fichier si nécessaire
generate_dot_file("arbre.json", "decision_tree_julia.dot")