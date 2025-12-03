include("data_loading.jl")
include("Glouton/glouton.jl")
include("B&B/BandB.jl")
include("Glouton/fonctions_annexes.jl")
include("Visualisation/visualisation.jl")


function simplifie_arbre(noeud)
    # Détecter une vraie feuille : aucune branche, ou dictionnaire vide
    if !haskey(noeud, "branches") || isempty(noeud["branches"])
        # Prend "especes_restantes" si elle existe, sinon "species"
        especes = get(noeud, "especes_restantes", get(noeud, "species", []))
        return Dict("especes" => especes)
    end

    # Noeud interne
    branches_simpl = Dict{String, Any}()
    for (cle, sousnoeud) in noeud["branches"]
        branches_simpl[string(cle)] = simplifie_arbre(sousnoeud)
    end

    return Dict(
        "question" => noeud["question"],
        "branches" => branches_simpl
    )
end

@info "Chargement des données..."
data = JSON.parsefile("B&B/data_moy_test.json")
date = Dates.format(Dates.now(), "yyyy-mm-dd_HH-MM-SS")
@info "Données chargées avec succès."

#=====Initialisation des vecteurs======#
@info "Initialisation des vecteurs..."
v_q = Vector{String}() # questions
v_qc = Vector{Vector{Int}}() # caractéristiques par question
v_c = Vector{String}() # caractéristiques
v_uq = Vector{Vector{Int}}() # questions débloquées par caractéristique
nb_species = length(data["collection"]) # nombre d'espèces
sp_matrix = Ref(BitMatrix(undef, 0, 0)) # matrice des espèces référence afin de pouvoir avoir une taille dynamique
vect_species = Vector{String}(undef, nb_species) # vecteur des noms d'espèces
asked_questions = Vector{Int}()
accessible_questions = Vector{Int}()
@info "Initialisation des vecteurs terminée."

#=====Remplissage des vecteurs======#
@info "Remplissage des vecteurs..."
fill_variables!(v_q, v_qc, v_c, v_uq, sp_matrix, vect_species, data) 
species_matrix = sp_matrix[] # Conversion de Ref{BitMatrix} à BitMatrix
remaining_species=collect(1:nb_species) # Remplissage des espèces restantes au départ
# Remplissage des questions accessibles au départ
for q in data["questions"]
    push!(accessible_questions, findfirst(==(q["title_q"]), v_q))
end
@info "Vecteurs remplis avec succès."

#=====Application de l'algorithme glouton======#
@info "Application de l'algorithme glouton..."
arbre=glouglouton(species_matrix, copy(remaining_species), copy(accessible_questions), v_qc, v_uq, copy(asked_questions))
arbre_json=JSON.json(arbre, 4)
@info "Algorithme glouton terminé."

@info "Sauvegarde de l'arbre glouton au format JSON..."
open("Trees/Glouton/arbre_glouton_$date.json", "w") do f
    write(f, arbre_json)
end

println("---------------------  --------------------------------------")
println(nb_species)
println("-----------------------------------------------------------")
println(size(v_q))

