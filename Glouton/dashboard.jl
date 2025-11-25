using Dash
import DashCoreComponents as dcc
import DashHtmlComponents as html
using DataFrames

# ==========================
#  KPI DES DEUX MÉTHODES
# ==========================
kpi_eval2 = Dict(
    "Nombre de feuilles" => 108,
    "Espèces moyennes / feuille" => 1.1666666666666667,
    "Profondeur max" => 13,
    "Nombre de noeuds internes" => 83,
    "Branches moyennes / noeud interne" => 2.289156626506024
)

kpi_eval3 = Dict(
    "Nombre de feuilles" => 21,
    "Espèces moyennes / feuille" => 3.238095238095238,
    "Profondeur max" => 5,
    "Nombre de noeuds internes" => 12,
    "Branches moyennes / noeud interne" => 2.6666666666666665
)

kpi_names = collect(keys(kpi_eval2))

# DataFrame pour le tableau
df = DataFrame(
    KPI = kpi_names,
    Evaluation2 = [kpi_eval2[k] for k in kpi_names],
    Evaluation3 = [kpi_eval3[k] for k in kpi_names]
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
                    "x" => ["Évaluation 2", "Évaluation 3"],
                    "y" => [kpi_eval2[kpi], kpi_eval3[kpi]],
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
                    "y" => [kpi_eval2[k] for k in kpi_names],
                    "type" => "bar",
                    "name" => "Évaluation 2"
                ),
                Dict(
                    "x" => kpi_names,
                    "y" => [kpi_eval3[k] for k in kpi_names],
                    "type" => "bar",
                    "name" => "Évaluation 3"
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
    html_h1("Dashboard comparatif des arbres (Évaluation2 vs Évaluation3)"),
    html_h2("Tableau comparatif des KPI"),
    html_table(
        [
            html_tr([html_th("KPI"), html_th("Évaluation 2"), html_th("Évaluation 3")]),
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
