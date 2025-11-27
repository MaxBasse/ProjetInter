using JSON

# Charge le JSON depuis un fichier
tree = JSON.parsefile("arbre_V1.json")
tree_Bnb = JSON.parsefile("Trees/BandB/arbre_simplifie_grand.json")
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

function analyze_BnB(node; depth=1, path=Int[])

    # ----- 1) FEUILLE -----
    if haskey(node, "especes")
        return Dict(
            :leaves => 1,
            :species_per_leaf => [length(node["especes"])],
            :max_depth => depth,
            :internal_nodes => 0,
            :branching_factors => Int[],
            :paths => [(path, node["especes"])]
        )
    end

    # ----- 2) CAS : PAS DE BRANCHES (BnB intermédiaire vide) -----
    if !haskey(node, "branches")
        # On traite ce nœud comme une "feuille vide"
        return Dict(
            :leaves => 1,
            :species_per_leaf => [0],
            :max_depth => depth,
            :internal_nodes => 0,
            :branching_factors => Int[],
            :paths => [(path, [])]
        )
    end

    # ----- 3) NOEUD INTERNE AVEC BRANCHES -----
    new_path = haskey(node, "question") ? vcat(path, node["question"]) : path

    results = [
        analyze_BnB(child; depth=depth+1, path=new_path)
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
#stats = analyze(tree)
stats = analyze_BnB(tree_Bnb)

println("\n=== KPIs SUR L'ARBRE ===")
println("Nombre total de feuilles                      :", stats[:leaves])
println("Nombre moyen d'espèces par feuille            :", sum(stats[:species_per_leaf])/length(stats[:species_per_leaf]))
println("Profondeur maximale (longueur max)            :", stats[:max_depth])
println("Nombre total de noeuds internes               :", stats[:internal_nodes])
println("Branches moyennes par noeud interne           :", sum(stats[:branching_factors])/length(stats[:branching_factors]))
println("Distribution du nombre d'espèces par feuille  :", stats[:species_per_leaf])

