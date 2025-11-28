include("metriques_arbre.jl") # charge le code (nécessite le fichier)

using Dash
import DashCoreComponents as dcc
import DashHtmlComponents as html
import DashCytoscape as cy # Ajout de l'import Cytoscape
using DataFrames
using JSON

# ==========================
#  CHARGEMENT DES DONNÉES
# ==========================
tree_1 = JSON.parsefile("Trees/Glouton/arbre_V1.json")
tree_2 = JSON.parsefile("Trees/Glouton/arbre_V2.json")
tree_3 = JSON.parsefile("Trees/BandB/arbre_simplifie_grand.json")

stats_1 = analyze(tree_1)
stats_2 = analyze(tree_2)
stats_3 = analyze_BnB(tree_3)

function generate_uuid()
    return string(UUIDs.uuid4())
end

# Pour utiliser UUID, il faut l'importer. J'ajoute donc l'import manquant.
using UUIDs

function tree_data_to_cytoscape(tree_data, id_prefix)
    elements = []
    
    # Fonction récursive pour parcourir l'arbre et construire les éléments
    function traverse_tree(node, parent_id, edge_label)
        node_uuid = generate_uuid() # ID unique pour ce nœud
        
        is_leaf = !haskey(node, "branches")
        node_label = ""
        node_class = ""
        
        if is_leaf
            # Nœud Feuille: Contient les espèces
            species = get(node, "species", [])
            node_label = "Espèces: " * join(species, ", ")
            node_class = "leaf"
        else
            # Nœud Interne: Contient la question
            question_id = get(node, "question", "Question Inconnue")
            node_label = "Question n°$question_id"
            node_class = "internal"
        end

        # Ajouter le Nœud
        push!(elements, Dict(
            "data" => Dict("id" => node_uuid, "label" => node_label, "full_data" => JSON.json(node)),
            "classes" => node_class
        ))

        # Ajouter l'Arête si ce n'est pas la racine
        if parent_id !== nothing
            # L'arête (réponse) est labellisée par la clé de la branche
            edge_id = generate_uuid()
            push!(elements, Dict(
                "data" => Dict(
                    "id" => edge_id, 
                    "source" => parent_id, 
                    "target" => node_uuid, 
                    "label" => string(edge_label) # Utilise la clé de la branche comme label
                ),
                "classes" => "edge"
            ))
        end

        # Parcourir les branches (enfants)
        if haskey(node, "branches")
            branches = get(node, "branches", Dict())
            for (branch_key, child_node) in branches
                # La clé de la branche (ex: "58", "102") est le label de l'arête
                traverse_tree(child_node, node_uuid, branch_key)
            end
        end
        return node_uuid
    end

    # Démarrer la traversée à partir du nœud racine
    traverse_tree(tree_data, nothing, nothing) 
    
    return elements
end

# Conversion des données d'arbre
# Nous stockons également le JSON brut pour le mode interactif
methods = Dict(
    "Minimiser Profondeur" => Dict(
        "stats" => stats_1, 
        "elements" => tree_data_to_cytoscape(tree_1, "tree1"),
        "full_tree" => tree_1
    ),
    "Minimiser Feuilles"   => Dict(
        "stats" => stats_2, 
        "elements" => tree_data_to_cytoscape(tree_2, "tree2"),
        "full_tree" => tree_2
    ),
    "Branch & Bound"       => Dict(
        "stats" => stats_3, 
        "elements" => tree_data_to_cytoscape(tree_3, "tree3"),
        "full_tree" => tree_3
    )
)

# ==========================
#  STYLES CYTOSCAPE (Ajout d'un style pour le chemin sélectionné)
# ==========================
stylesheet = [
    # Styles de base
    Dict(
        "selector" => "node",
        "style" => Dict(
            "content" => "data(label)",
            "text-valign" => "center",
            "text-halign" => "center",
            "background-color" => "#3B82F6", # Bleu Tailwind
            "color" => "white",
            "padding" => "10px",
            "shape" => "round-rectangle",
            "text-wrap" => "wrap",
            "font-size" => "10px",
            "width" => "label",
            "height" => "label",
            "border-width" => "2px",
            "border-color" => "transparent"
        )
    ),
    Dict(
        "selector" => ".leaf",
        "style" => Dict(
            "background-color" => "#10B981", # Vert émeraude
            "shape" => "ellipse"
        )
    ),
    Dict(
        "selector" => "edge",
        "style" => Dict(
            "curve-style" => "bezier",
            "target-arrow-shape" => "triangle",
            "line-color" => "#9CA3AF",
            "target-arrow-color" => "#9CA3AF",
            "label" => "data(label)",
            "font-size" => "8px",
            "text-background-opacity" => 1,
            "text-background-color" => "#FFFFFF"
        )
    ),
    # Style pour le nœud actuel dans la navigation pas à pas
    Dict(
        "selector" => ".current-node",
        "style" => Dict(
            "background-color" => "#F59E0B", # Jaune Ambre
            "border-color" => "#B45309",
            "border-width" => "3px",
            "shape" => "star" # Met en évidence le nœud actuel
        )
    ),
    # Style pour les arêtes du chemin parcouru
    Dict(
        "selector" => ".followed-path",
        "style" => Dict(
            "line-color" => "#EF4444", # Rouge
            "target-arrow-color" => "#EF4444",
            "z-index" => 999
        )
    )
]

# ==========================
#  DASHBOARD LAYOUT (Ajout des composants pour le mode pas à pas)
# ==========================
app = dash()

app.layout = html_div(style = Dict("padding" => "20px"), children = [
    html_h1("Dashboard des Clés de Détermination de Flore", style = Dict("text-align" => "center", "color" => "#1F2937")),
    
    # Stockage de l'arbre complet et du chemin parcouru pour la navigation interactive
    dcc_store(id = "current_tree_json"),
    dcc_store(id = "current_node_data"),
    dcc_store(id = "path_elements", data = Dict()), # Stocke les IDs des éléments du chemin

    html_div(style = Dict("display" => "flex", "justify-content" => "center", "margin-bottom" => "30px"), children = [
        dcc_dropdown(
            id = "method_select",
            options = [
                Dict("label" => "Minimiser Profondeur (Arbre V1)", "value" => "Minimiser Profondeur"),
                Dict("label" => "Minimiser Feuilles (Arbre V2)",   "value" => "Minimiser Feuilles"),
                Dict("label" => "Branch & Bound (Arbre Simplifié)",       "value" => "Branch & Bound")
            ],
            value = "Minimiser Profondeur",
            style = Dict("width" => "400px")
        ),
    ]),

    # Conteneur principal: KPI + Graphe
    html_div(id = "content_container", style = Dict("display" => "flex", "justify-content" => "space-around")),

    html_h2("Mode Clé de Détermination Interactive", style = Dict("margin-top" => "40px", "color" => "#1F2937")),
    
    # Zone d'interaction pas à pas
    html_div(style = Dict("display" => "flex", "justify-content" => "space-around", "padding" => "20px", "background-color" => "#F3F4F6", "border-radius" => "8px"), children = [
        html_div(id = "interactive_question_area", style = Dict("flex" => "1", "padding-right" => "20px")),
        html_div(id = "interactive_result_area", style = Dict("flex" => "1", "padding-left" => "20px", "border-left" => "1px solid #D1D5DB")),
    ])
])

# ==========================
#  CALLBACK 1: MISE À JOUR DU DASHBOARD & INITIALISATION INTERACTIVE
# ==========================
callback!(
    app,
    Output("content_container", "children"),
    Output("current_tree_json", "data"),
    Output("current_node_data", "data"),
    Output("path_elements", "data"),
    Input("method_select", "value")
) do selected_method
    
    selected_data = methods[selected_method]
    selected_stats = selected_data["stats"]
    selected_elements = selected_data["elements"]
    full_tree = selected_data["full_tree"]

    # 1. Construction du Tableau KPI
    rows = [
        html_tr(style = Dict("border-bottom" => "1px solid #E5E7EB"), children = [
            html_td(k, style = Dict("padding" => "8px 12px", "color" => "#4B5563")), 
            html_td(string(round(selected_stats[k], digits=2)), style = Dict("padding" => "8px 12px", "font-weight" => "bold", "color" => "#1F2937"))
        ])
        for k in keys(selected_stats)
    ]

    table = html_div(
        style = Dict(
            "flex" => "0 0 350px",
            "padding" => "20px",
            "background-color" => "#F3F4F6",
            "border-radius" => "8px",
            "box-shadow" => "0 4px 6px -1px rgba(0, 0, 0, 0.1)"
        ),
        children = [
            html_h3("Indicateurs Clés de Performance", style = Dict("margin-top" => "0", "color" => "#1F2937")),
            html_table(
                vcat([html_tr([html_th("KPI", style = Dict("text-align" => "left")), html_th("Valeur", style = Dict("text-align" => "right"))])], rows),
                style = Dict(
                    "width" => "100%", 
                    "border-collapse" => "collapse"
                )
            )
        ]
    )

    # 2. Construction du Graphe Cytoscape
    # Pour l'affichage initial, on peut mettre en évidence le nœud racine
    initial_elements = deepcopy(selected_elements)
    root_node_id = initial_elements[1]["data"]["id"]
    initial_elements[1]["classes"] = "current-node" # Marquer le nœud racine

    tree_graph = cy_cytoscape(
        id = "decision_tree_graph",
        layout = Dict("name" => "breadthfirst", "padding" => 10), 
        style = Dict(
            "width" => "60%", 
            "height" => "800px", 
            "border" => "1px solid #D1D5DB", 
            "border-radius" => "8px"
        ),
        stylesheet = stylesheet,
        elements = initial_elements
    )
    
    # Retourne le layout, le JSON de l'arbre complet, les données du nœud racine, et un chemin vide
    return [
        table,
        html_div(tree_graph, style = Dict("flex" => "1", "margin-left" => "30px"))
    ], JSON.json(full_tree), JSON.json(full_tree), Dict()
end

# ==========================
#  CALLBACK 2: AFFICHAGE DE LA QUESTION INTERACTIVE
# ==========================
callback!(
    app,
    Output("interactive_question_area", "children"),
    Output("interactive_result_area", "children"),
    Input("current_node_data", "data"),
    prevent_initial_call=false
) do current_node_json
    
    if current_node_json === nothing || isempty(current_node_json)
        return html_div("Veuillez sélectionner une méthode."), html_div()
    end

    current_node = JSON.parse(current_node_json)

    # Si c'est une feuille, afficher le résultat final
    if haskey(current_node, "species")
        species_list = current_node["species"]
        
        result_content = [
            html_h3("Détermination Complète!"),
            html_p("Votre échantillon correspond aux espèces : ", style = Dict("font-size" => "1.1em")),
            html_ul([html_li("Espèce ID: $s", style = Dict("font-weight" => "bold", "color" => "#10B981")) for s in species_list])
        ]
        return html_div(result_content), html_div()

    # Si c'est un nœud interne, afficher la question et les options
    elseif haskey(current_node, "question") && haskey(current_node, "branches")
        question_id = current_node["question"]
        branches = current_node["branches"]
        
        question_content = [
            html_h3("Étape de Détermination"),
            html_p("Question actuelle ID: $(question_id)", style = Dict("font-style" => "italic")),
            html_p("Veuillez choisir la réponse qui correspond à votre spécimen :", style = Dict("font-weight" => "bold")),
            
            html_div([
                html_button(
                    "Réponse : $branch_key",
                    id = Dict("type" => "branch-button", "branch_key" => branch_key),
                    n_clicks = 0,
                    style = Dict(
                        "margin" => "5px", 
                        "padding" => "10px 15px", 
                        "backgroundColor" => "#3B82F6", 
                        "color" => "white", 
                        "border-radius" => "5px",
                        "border" => "none",
                        "cursor" => "pointer"
                    )
                )
                for branch_key in sort(collect(keys(branches)))
            ])
        ]
        return html_div(question_content), html_div()
    else
        return html_div("Structure de nœud non reconnue."), html_div()
    end
end

# ==========================
#  CALLBACK 3: NAVIGATION INTERACTIVE (MISE À JOUR DU NŒUD ACTUEL ET DU GRAPHE)
# ==========================
callback!(
    app,
    Output("current_node_data", "data"), # Correction de la syntaxe Julia
    Output("decision_tree_graph", "elements"),                
    Output("path_elements", "data"),    # Correction de la syntaxe Julia
    Input((type="branch-button", branch_key=ALL), "n_clicks"),
    State("current_node_data", "data"),
    State("current_tree_json", "data"),
    State("path_elements", "data"),
    State("decision_tree_graph", "elements"),
    prevent_initial_call=true
) do clicks, current_node_json, full_tree_json, path_elements, graph_elements
    
    # Trouver le bouton cliqué
    ctx = callback_context()
    if isempty(ctx.triggered)
        throw(PreventUpdate())
    end
    
    trigger_id = ctx.triggered[1].prop_id
    trigger_value = ctx.triggered[1].value
    
    # On vérifie que le clic est nouveau
    if trigger_value == 0
        throw(PreventUpdate())
    end

    # Extraction de la clé de branche (la réponse) cliquée
    # Exemple: {"type":"branch-button","branch_key":"58"}
    branch_key = JSON.parse(split(trigger_id, ".")[1])["branch_key"]
    
    current_node = JSON.parse(current_node_json)
    full_tree = JSON.parse(full_tree_json)
    
    # 1. Trouver le prochain nœud
    next_node = current_node["branches"][branch_key]
    
    # 2. Mettre à jour les éléments du graphe (visualisation du chemin)
    
    # On trouve l'ID Cytoscape du nœud actuel (source)
    # Le label du nœud interne est "Question n°X". On doit trouver son ID.
    current_question_id = current_node["question"]
    
    source_node_id = ""
    source_node_data = Dict()
    for element in graph_elements
        if haskey(element, "data") && get(element["data"], "label", "") == "Question n°$current_question_id" && element["classes"] != "leaf"
            source_node_id = element["data"]["id"]
            source_node_data = JSON.parse(element["data"]["full_data"])
            break
        end
    end
    
    # On trouve l'ID Cytoscape du nœud cible
    target_node_id = ""
    for element in graph_elements
        if haskey(element, "data") && get(element["data"], "full_data", "") == JSON.json(next_node)
            target_node_id = element["data"]["id"]
            break
        end
    end

    # Si le nœud cible est trouvé, on marque le chemin et le nœud cible
    if !isempty(target_node_id)
        # Nettoyer les classes du précédent nœud actuel
        for element in graph_elements
            if haskey(element, "classes")
                element["classes"] = replace(element["classes"], "current-node" => "")
            end
        end
        
        # Marquer le nœud cible comme le nouveau nœud actuel
        for element in graph_elements
            if get(element["data"], "id", "") == target_node_id
                element["classes"] = get(element, "classes", "") * " current-node"
                break
            end
        end

        # Mettre à jour le chemin parcouru
        new_path_elements = path_elements
        
        # Trouver l'arête (la réponse) cliquée
        edge_id = ""
        for element in graph_elements
            if get(element, "classes", "") == "edge" && get(element["data"], "source", "") == source_node_id && get(element["data"], "target", "") == target_node_id
                edge_id = get(element["data"], "id", "")
                break
            end
        end
        
        if !isempty(edge_id)
            new_path_elements[edge_id] = true
        end
        
        # Appliquer les classes de chemin aux arêtes sauvegardées
        for element in graph_elements
            if get(element["data"], "id", "") in keys(new_path_elements) && get(element, "classes", "") == "edge"
                element["classes"] = get(element, "classes", "") * " followed-path"
            end
        end
        
        # Retourner le nouveau nœud actuel, les éléments de graphe mis à jour, et le chemin mis à jour
        return JSON.json(next_node), graph_elements, new_path_elements
    end
    
    # Cas d'erreur/non trouvé
    @error "Erreur de navigation: Nœud cible non trouvé pour la branche $branch_key."
    return current_node_json, graph_elements, path_elements
end

# ==========================
#  LANCEMENT SERVEUR
# ==========================
run_server(app, "127.0.0.1", 8050)