using JSON

mutable struct Noeud
    cle_partielle::Dict{Any, Any}           # Clé de détermination partielle
    borne_inf::Int              # borne inf associée à chaque noeud du B&B 
end

data = JSON.parsefile(joinpath(@__DIR__, "petite_data_test.json"))
#data = JSON.parsefile(joinpath(@__DIR__, "data.json"))

include("BandB.jl")
include("../data_parsing.jl")




df_caract_species = species_matrix
question_unlock = vect_unlock_q
questions_answers = vect_question_carac


E_initial = collect(1:size(species_matrix)[1])

Qa_initial = Vector{Int}()
for q in data["questions"]
    push!(Qa_initial, findfirst(==(q["title_q"]), vect_question))
end

println("-----------------------------------------------------------")
println(question_unlock)
println("-----------------------------------------------------------")
println(questions_answers)

Branch_and_Bound(Qa_initial, E_initial, df_caract_species, question_unlock, questions_answers)

"""
sol_glouton = glouglouton(df_caract_species, E_initial, Qa_initial, questions_answers, question_unlock)
# Calcul initial de la borne supérieure via le glouton
borne_sup = profondeur_arbre(sol_glouton)
"""
