using Dash
import DashCoreComponents as dcc
import DashHtmlComponents as html
using DataFrames
using JSON

# ==========================
#  CHARGEMENT DES DONNÉES
# ==========================
tree_1 = JSON.parsefile("arbre_V1.json")
tree_2 = JSON.parsefile("arbre_V2.json")
stats_1 = analyze(tree_1)
stats_2 = analyze(tree_2)

# ==========================
#  KPI DES DEUX MÉTHODES
# ==========================
kpi_eval1 = Dict(
    "Nombre de feuilles" => stats_1[:leaves],
    "Espèces moyennes / feuille" => sum(stats_1[:species_per_leaf]) / length(stats_1[:species_per_leaf]),
    "Profondeur max" => stats_1[:max_depth],
    "Nombre de noeuds internes" => stats_1[:internal_nodes],
    "Branches moyennes / noeud interne" => sum(stats_1[:branching_factors]) / length(stats_1[:branching_factors])
)

kpi_eval2 = Dict(
    "Nombre de feuilles" => stats_2[:leaves],
    "Espèces moyennes / feuille" => sum(stats_2[:species_per_leaf]) / length(stats_2[:species_per_leaf]),
    "Profondeur max" => stats_2[:max_depth],
    "Nombre de noeuds internes" => stats_2[:internal_nodes],
    "Branches moyennes / noeud interne" => sum(stats_2[:branching_factors]) / length(stats_2[:branching_factors])
)

methods = Dict(
    "Minimiser Profondeur" => kpi_eval1,
    "Minimiser Feuilles"   => kpi_eval2
)

# ==========================
#  DASHBOARD
# ==========================
app = dash()

app.layout = html_div([
    html_h1("Dashboard des KPI"),
    dcc_dropdown(
        id = "method_select",
        options = [
            Dict("label" => "Minimiser Profondeur", "value" => "Minimiser Profondeur"),
            Dict("label" => "Minimiser Feuilles",   "value" => "Minimiser Feuilles")
        ],
        value = "Minimiser Profondeur",
        style = Dict("width" => "40%", "margin-bottom" => "20px")
    ),
    html_div(id = "content_container")
])

# ==========================
#  CALLBACK
# ==========================
callback!(
    app,
    Output("content_container", "children"),
    Input("method_select", "value")
) do selected_method
    selected_stats = methods[selected_method]

    # Générer le tableau des KPI
    rows = [
        html_tr([html_td(k), html_td(string(selected_stats[k]))])
        for k in keys(selected_stats)
    ]
    table = html_table(
        vcat(
            [html_tr([html_th("KPI"), html_th("Valeur")])],
            rows
        ),
        style = Dict(
            "border" => "1px solid black",
            "border-collapse" => "collapse",
            "padding" => "12px",
            "width" => "600px"
        )
    )

    # URLs directes des images
    image_url = selected_method == "Minimiser Profondeur" ?
        "https://i.ibb.co/bj5gNYZC/graph-1.png" :
        "https://i.ibb.co/MDJqTZzG/graph-2.png"

    # Créer le composant image
    image = html_img(
        src = image_url,
        style = Dict(
            "width" => "600px",
            "height" => "auto",
            "margin-left" => "200px"
        )
    )

    # Retourner le tableau et l'image côte à côte
    return html_div([
        html_div(table, style = Dict("display" => "inline-block", "vertical-align" => "top")),
        html_div(image, style = Dict("display" => "inline-block"))
    ])
end

# ==========================
#  LANCEMENT DU SERVEUR
# ==========================
run_server(app, "127.0.0.1", 8050)
