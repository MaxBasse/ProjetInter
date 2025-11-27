include("data_loading.jl")
include("Glouton/glouton.jl")
include("Glouton/fonctions_annexes.jl")
include("Visualisation/visualisation.jl")

data = JSON.parsefile("Glouton/data.json")

#=====Initialisation des vecteurs======#

v_q = Vector{String}() # questions
v_qc = Vector{Vector{Int}}() # caractéristiques par question
v_c = Vector{String}() # caractéristiques
v_uq = Vector{Vector{Int}}() # questions débloquées par caractéristique
nb_species = length(data["collection"]) # nombre d'espèces
sp_matrix = Ref(BitMatrix(undef, 0, 0)) # matrice des espèces référence afin de pouvoir avoir une taille dynamique
vect_species = Vector{String}(undef, nb_species) # vecteur des noms d'espèces

#=====Remplissage des vecteurs======#
fill_variables!(v_q, v_qc, v_c, v_uq, sp_matrix, vect_species, data)
species_matrix = sp_matrix[] # Conversion de Ref{BitMatrix} à BitMatrix

#=====Application de l'algorithme glouton======#
remaining_species=collect(1:nb_species)
asked_questions = Vector{Int}()
accessible_questions = Vector{Int}()

# Remplissage du vecteur des questions accessibles au départ
for q in data["questions"]
    push!(accessible_questions, findfirst(==(q["title_q"]), v_q))
end

#Application de l'algo
arbre=glouglouton(new_species_matrix, remaining_species, accessible_questions, v_qc, v_uq, asked_questions)
arbre_json=JSON.json(arbre, 4)

#Sauvegarde de l'arbre au format JSON
open("arbre_V1.json", "w") do f
    write(f, arbre_json)
end

#Génération de la visualisation SVG de l'arbre
generate_botanic_svg("arbre_V1.json", "Visualisation/arbre_V1.svg", v_q, v_c, vect_species)
generate_botanic_svg("arbre_simplifie_grand.json", "Visualisation/arbre_simplifie_grand.svg", v_q, v_c, vect_species)

