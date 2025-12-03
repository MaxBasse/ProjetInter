include("data_loading.jl")
include("Glouton/glouton.jl")
include("B&B/BandB2.jl")
include("Glouton/fonctions_annexes.jl")
include("Visualisation/visualisation.jl")

@info "Chargement des données depuis data.json..."
data = JSON.parsefile("B&B/data.json")

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
arbre=glouglouton(species_matrix, remaining_species, accessible_questions, v_qc, v_uq, asked_questions)
arbre_json=JSON.json(arbre, 4)
@info "Algorithme glouton terminé."

@info "Sauvegarde de l'arbre glouton au format JSON..."
open("arbre_V3.json", "w") do f
    write(f, arbre_json)
end

"""
#=====Application de l'algorithme Branch and Bound======#
@info "Application de l'algorithme Branch and Bound..."
meilleure_solution, borne_sup =Branch_and_Bound(accessible_questions, remaining_species, species_matrix, v_uq, v_qc)
@info "Algorithme Branch and Bound terminé."

@info "Simplification de l'arbre Branch and Bound..."
arbre_simplifie = simplifie_arbre(meilleure_solution)
json_str = JSON.json(arbre_simplifie, 4)

@info "Sauvegarde de l'arbre simplifié au format JSON..."
open("arbre_simplifie_grand.json", "w") do f
    write(f, json_str)
end

#=====Génération de la visualisation SVG======#
@info "Génération de la visualisation SVG de l'arbre..."
generate_botanic_svg("arbre_V1.json", "Visualisation/arbre_V1.svg", v_q, v_c, vect_species)
generate_botanic_svg("arbre_simplifie_grand.json", "Visualisation/arbre_simplifie_grand.svg", v_q, v_c, vect_species)


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
end"""