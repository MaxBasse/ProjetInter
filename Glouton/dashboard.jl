using Dash
import DashCoreComponents as dcc
import DashHtmlComponents as html
using DataFrames
tree_1 = JSON.parsefile("Glouton/arbre.json")
tree_2=JSON.parsefile("Glouton/arbre_V2.json")
stats_1 = analyze(tree_1)
stats_2 = analyze(tree_2)


# ==========================
#  KPI DES DEUX MÉTHODES
# ==========================
kpi_eval1 = Dict(
    "Nombre de feuilles" => stats_1[:leaves],
    "Espèces moyennes / feuille" => sum(stats_1[:species_per_leaf])/length(stats_1[:species_per_leaf]),
    "Profondeur max" => stats_1[:max_depth],
    "Nombre de noeuds internes" => stats_1[:internal_nodes],
    "Branches moyennes / noeud interne" => sum(stats_1[:branching_factors])/length(stats_1[:branching_factors])
)

kpi_eval2 = Dict(
   "Nombre de feuilles" => stats_2[:leaves],
    "Espèces moyennes / feuille" => sum(stats_2[:species_per_leaf])/length(stats_2[:species_per_leaf]),
    "Profondeur max" => stats_2[:max_depth],
    "Nombre de noeuds internes" => stats_2[:internal_nodes],
    "Branches moyennes / noeud interne" => sum(stats_2[:branching_factors])/length(stats_2[:branching_factors])
)

kpi_names = collect(keys(kpi_eval1))

# DataFrame pour le tableau
df = DataFrame(
    KPI = kpi_names,
    Evaluation2 = [kpi_eval1[k] for k in kpi_names],
    Evaluation3 = [kpi_eval2[k] for k in kpi_names]
)

# ==========================
#  FONCTIONS DE GRAPHIQUES (avec DashCoreComponents)
# ==========================
function generate_bar_chart(kpi)
    dcc_graph(
        id = "bar-$kpi",
        figure = Dict(
            "data" => [
                Dict(
                    "x" => ["Minimiser Profondeur", "Minimiser Feuilles"],
                    "y" => [kpi_eval1[kpi], kpi_eval2[kpi]],
                    "type" => "bar",
                    "name" => kpi
                )
            ],
            "layout" => Dict(
                "title" => kpi,
                "xaxis" => Dict("title" => "Méthode"),
                "yaxis" => Dict("title" => "Valeur")
            )
        )
    )
end

function generate_global_comparison()
    dcc_graph(
        id = "global-comparison",
        figure = Dict(
            "data" => [
                Dict(
                    "x" => kpi_names,
                    "y" => [kpi_eval1[k] for k in kpi_names],
                    "type" => "bar",
                    "name" => "Minimiser Profondeur"
                ),
                Dict(
                    "x" => kpi_names,
                    "y" => [kpi_eval2[k] for k in kpi_names],
                    "type" => "bar",
                    "name" => "Minimiser Feuilles"
                )
            ],
            "layout" => Dict(
                "title" => "Comparaison globale des KPI",
                "xaxis" => Dict("title" => "Indicateur"),
                "barmode" => "group"
            )
        )
    )
end

# ==========================
#  DASHBOARD LAYOUT
# ==========================
app = dash()

app.layout = html_div([
    html_h1("Dashboard comparatif des arbres selon le score"),
    html_h2("Tableau comparatif des KPI"),
    html_table(
        [
            html_tr([html_th("KPI"), html_th("Minimiser Profondeur"), html_th("Minimiser Feuilles")]),
            [html_tr([html_td(df[i, :KPI]), html_td(df[i, :Evaluation2]), html_td(df[i, :Evaluation3])]) for i in 1:nrow(df)]
        ],
        style = Dict("border" => "1px solid black", "border-collapse" => "collapse", "width" => "50%")
    ),
    html_hr(),
    html_h2("Comparaison globale"),
    generate_global_comparison(),
    html_hr(),
    html_h2("Comparaison KPI par KPI"),
    html_div([
        dcc_dropdown(
            id = "kpi_select",
            options = [(label = k, value = k) for k in kpi_names],
            value = kpi_names[1]
        ),
        html_div(id = "kpi_graph_container")
    ])
])

# ==========================
#  CALLBACK INTERACTIF
# ==========================
callback!(
    app,
    Output("kpi_graph_container", "children"),
    Input("kpi_select", "value")
) do selected_kpi
    generate_bar_chart(selected_kpi)
end

# ==========================
#  LANCEMENT DU SERVEUR
# ==========================
run_server(app, "127.0.0.1", 8050)
