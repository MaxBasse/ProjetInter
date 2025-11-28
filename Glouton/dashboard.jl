include("metriques_arbre.jl")  # charge le code


using Dash
import DashCoreComponents as dcc
import DashHtmlComponents as html
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

# ==========================
#  KPI DES MÉTHODES
# ==========================
kpi_eval1 = Dict(
    "Nombre de feuilles" => stats_1[:leaves],
    "Espèces moyennes / feuille" => sum(stats_1[:species_per_leaf]) / length(stats_1[:species_per_leaf]),
    "Profondeur max" => stats_1[:max_depth],
    "Nombre de noeuds internes" => stats_1[:internal_nodes],
    "Branches moyennes / noeud interne" => sum(stats_1[:branching_factors]) / length(stats_1[:branching_factors]),
    "Temps de calcul (s)" => 0.0  # Placeholder
)

kpi_eval2 = Dict(
    "Nombre de feuilles" => stats_2[:leaves],
    "Espèces moyennes / feuille" => sum(stats_2[:species_per_leaf]) / length(stats_2[:species_per_leaf]),
    "Profondeur max" => stats_2[:max_depth],
    "Nombre de noeuds internes" => stats_2[:internal_nodes],
    "Branches moyennes / noeud interne" => sum(stats_2[:branching_factors]) / length(stats_2[:branching_factors]),
    "Temps de calcul (s)" => 0.0  # Placeholder
)

kpi_eval3 = Dict(
    "Nombre de feuilles" => stats_3[:leaves],
    "Espèces moyennes / feuille" => sum(stats_3[:species_per_leaf]) / length(stats_3[:species_per_leaf]),
    "Profondeur max" => stats_3[:max_depth],
    "Nombre de noeuds internes" => stats_3[:internal_nodes],
    "Branches moyennes / noeud interne" => sum(stats_3[:branching_factors]) / length(stats_3[:branching_factors]),
    "Temps de calcul (s)" => 0.0  # Placeholder
)

methods = Dict(
    "Minimiser Profondeur" => kpi_eval1,
    "Minimiser Feuilles"   => kpi_eval2,
    "Branch & Bound"       => kpi_eval3
)

#  Mappage des KPI avec des icônes et couleurs pour l'affichage stylisé
# Les clés sont ici les chaînes exactes (String) utilisées dans les dictionnaires kpi_eval.
KPI_INFO = Dict(
    "Nombre de feuilles" => Dict("icon" => "🌿", "color" => "#10B981", "unit" => "feuilles"), 
    "Espèces moyennes / feuille" => Dict("icon" => "📊", "color" => "#3B82F6", "unit" => "espèces"), 
    "Profondeur max" => Dict("icon" => "🌳", "color" => "#EF4444", "unit" => "niveaux"), 
    "Nombre de noeuds internes" => Dict("icon" => "🔗", "color" => "#F59E0B", "unit" => "noeuds"), 
    "Branches moyennes / noeud interne" => Dict("icon" => "🧭", "color" => "#8B5CF6", "unit" => "branches"),
    "Temps de calcul (s)" => Dict("icon" => "⏱️", "color" => "#1F2937", "unit" => "secondes") # Nouveau KPI de temps
)

# ==========================
#  DASHBOARD LAYOUT (Styles Modernisés)
# ==========================
app = dash()

app.layout = html_div(style = Dict("font-family" => "Inter, sans-serif", "padding" => "20px", "background-color" => "#F9FAFB"), children = [
    html_h1("Dashboard d'Analyse des Clés de Détermination", 
        style = Dict("text-align" => "center", "color" => "#1F2937", "margin-bottom" => "40px")
    ),
    
    html_div(style = Dict("display" => "flex", "justify-content" => "center", "margin-bottom" => "30px"), children = [
        html_p("Sélectionnez la méthode d'optimisation :", style = Dict("margin-right" => "15px", "align-self" => "center", "font-weight" => "bold", "color" => "#4B5563")),
        dcc_dropdown(
            id = "method_select",
            options = [
                Dict("label" => "Minimiser Profondeur (Glouton V1)", "value" => "Minimiser Profondeur"),
                Dict("label" => "Minimiser Feuilles (Glouton V2)",   "value" => "Minimiser Feuilles"),
                Dict("label" => "Branch & Bound (BnB)",       "value" => "Branch & Bound")
            ],
            value = "Minimiser Profondeur",
            style = Dict("width" => "300px", "border-radius" => "8px")
        )
    ]),

    html_div(id = "content_container", 
        style = Dict("display" => "flex", "justify-content" => "space-around", "flex-wrap" => "wrap")
    )
])

# ==========================
#  CALLBACK - MISE À JOUR VISUELLE
# ==========================
callback!(
    app,
    Output("content_container", "children"),
    Input("method_select", "value")
) do selected_method

    selected_data = methods[selected_method]
    
    # 1. Cartes KPI stylisées
    kpi_cards = []
    # On itère sur les clés String du dictionnaire de stats
    for (kpi_name, kpi_value) in selected_data
        
        # Le lookup pour l'info utilise le kpi_name (qui est une String)
        info = get(KPI_INFO, kpi_name, Dict("icon" => "❓", "color" => "#6B7280", "unit" => "", "name" => kpi_name)) 
        
        # Déterminer le nom à afficher (c'est kpi_name car c'est déjà la chaîne de caractères formatée)
        
        # Formater la valeur (arrondi à 2 décimales si un nombre, sinon tel quel)
        display_value = ""
        if isa(kpi_value, AbstractVector) && !isempty(kpi_value)
             # Cas où la valeur est une liste (comme pour les facteurs d'embranchement)
             value = kpi_value[1]
             display_value = string(round(value, digits=2))
        elseif isa(kpi_value, Number)
             display_value = string(round(kpi_value, digits=2))
        else
            display_value = string(kpi_value)
        end
        
        push!(kpi_cards, 
            html_div(style = Dict(
                "flex" => "0 0 25%", # CORRECTION APPLIQUÉE: Ajustement pour 3 cartes par ligne (31% + marges)
                "margin" => "10px",
                "padding" => "20px",
                "background-color" => "white",
                "border-radius" => "12px",
                "box-shadow" => "0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.06)",
                "border-top" => "4px solid $(info["color"])"
            ), children = [
                html_div(info["icon"], style = Dict("font-size" => "2.5em", "color" => info["color"], "margin-bottom" => "10px")),
                html_p(kpi_name, style = Dict("font-size" => "0.9em", "color" => "#6B7280", "margin-bottom" => "5px")),
                html_h3(display_value, style = Dict("font-size" => "1.8em", "color" => "#1F2937", "margin-top" => "0")),
                html_p(info["unit"], style = Dict("font-size" => "0.7em", "color" => "#9CA3AF"))
            ])
        )
    end
    
    kpi_container = html_div(kpi_cards, style = Dict("display" => "flex", "flex-wrap" => "wrap", "justify-content" => "space-around", "width" => "100%", "margin-bottom" => "40px"))

    # 2. Section de visualisation (Image)
    if selected_method == "Minimiser Profondeur"
        image_url = "https://i.ibb.co/bj5gNYZC/graph-1.png"
    elseif selected_method == "Minimiser Feuilles"
        image_url = "https://i.ibb.co/MDJqTZzG/graph-2.png"
    else
        image_url = "https://i.ibb.co/hRMqP14s/graph-3.png"
    end

    image_section = html_div(
        style = Dict(
            "width" => "100%", 
            "text-align" => "center", 
            "padding" => "20px", 
            "background-color" => "white", 
            "border-radius" => "12px",
            "box-shadow" => "0 4px 6px -1px rgba(0, 0, 0, 0.1)"
        ),
        children = [
            html_h3("Visualisation de l'Arbre de Détermination", style = Dict("color" => "#1F2937")),
            html_img(
                src = image_url,
                alt = "Graphe pour la méthode $selected_method",
                style = Dict(
                    "max-width" => "90%",
                    "height" => "auto",
                    "border-radius" => "8px",
                    "margin-top" => "15px"
                )
            )
        ]
    )

    # -- RETOUR DU CALLBACK --
    return html_div([
        kpi_container,
        image_section
    ])
end

# ==========================
#  LANCEMENT SERVEUR (Prêt pour le déploiement)
# ==========================
# Récupère le port et l'hôte de l'environnement, sinon utilise 8050 et 0.0.0.0
port = get(ENV, "PORT", "8050") 
host = get(ENV, "HOST", "0.0.0.0") 
run(`cmd /c start http://127.0.0.1:8050`)
run_server(app, host, parse(Int, port))