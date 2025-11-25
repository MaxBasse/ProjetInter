using JSON

# Charge le JSON depuis un fichier
tree = JSON.parsefile("arbre_V2.json")

"""
Analyse récursive de l'arbre

Args:
  node   : dictionnaire représentant un noeud
  depth  : profondeur actuelle
  path   : chemin des questions depuis la racine

Returns:
  Dict contenant :
    :leaves              → nombre de feuilles
    :species_per_leaf    → tableau tailles des feuilles
    :max_depth           → profondeur maximale
    :internal_nodes      → nombre de noeuds internes
    :branching_factors   → branches par noeud interne
    :paths               → tous les chemins complets (racine → feuille)
"""
function analyze(node; depth=1, path=Int[])
    # FEUILLE : contient "species"
    if haskey(node, "species")
        return Dict(
            :leaves => 1,
            :species_per_leaf => [length(node["species"])],
            :max_depth => depth,
            :internal_nodes => 0,
            :branching_factors => Int[],
            :paths => [(path, node["species"])]
        )
    end

    # NOEUD NON-FEUILLE
    # On ajoute la question actuelle au chemin si elle existe
    new_path = haskey(node, "question") ? vcat(path, node["question"]) : path

    results = [
        analyze(child; depth=depth+1, path=new_path)
        for (_, child) in node["branches"]
    ]

    return Dict(
        :leaves => sum(r[:leaves] for r in results),
        :species_per_leaf => vcat([r[:species_per_leaf] for r in results]...),
        :max_depth => maximum(r[:max_depth] for r in results),
        :internal_nodes => 1 + sum(r[:internal_nodes] for r in results),
        :branching_factors =>
            [length(node["branches"]);
             vcat([r[:branching_factors] for r in results]...)],
        :paths => vcat([r[:paths] for r in results]...)
    )
end

# Analyse
stats = analyze(tree)

println("\n=== KPIs SUR L'ARBRE ===")
println("Nombre total de feuilles                      :", stats[:leaves])
println("Nombre moyen d'espèces par feuille            :", sum(stats[:species_per_leaf])/length(stats[:species_per_leaf]))
println("Profondeur maximale (longueur max)            :", stats[:max_depth])
println("Nombre total de noeuds internes               :", stats[:internal_nodes])
println("Branches moyennes par noeud interne           :", sum(stats[:branching_factors])/length(stats[:branching_factors]))
println("Distribution du nombre d'espèces par feuille  :", stats[:species_per_leaf])

# Extraction des chemins les plus longs
max_len = stats[:max_depth]
longest_paths = filter(x -> length(x[1]) == max_len - 1, stats[:paths]) 
# (on retire 1 car la profondeur compte la feuille elle-même)

println("\n=== PLUS LONGS CHEMINS ===")
println("Nombre de chemins les plus longs :", length(longest_paths))

for (i, (questions, species)) in enumerate(longest_paths)
    println("\nChemin $i :")
    println("Questions : ", questions)
    println("Espèces en feuille : ", species)
end



using DataFrames
using Plots
using Statistics

# ==============================
# KPI des deux méthodes
# ==============================

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

# ==============================
# Construction du DataFrame
# ==============================

kpi_names = collect(keys(kpi_eval2))

df = DataFrame(
    KPI = kpi_names,
    Evaluation2 = [kpi_eval2[k] for k in kpi_names],
    Evaluation3 = [kpi_eval3[k] for k in kpi_names]
)

println("\n=== Tableau comparatif ===")
println(df)

default(titlefont=12, legendfontsize=10)

for kpi in kpi_names
    vals = [kpi_eval2[kpi], kpi_eval3[kpi]]

    p=bar(
        ["Eval2", "Eval3"],
        vals,
        title = kpi,
        xlabel = "Méthode",
        ylabel = "Valeur",
        legend = false
    )
    display(p)
end
