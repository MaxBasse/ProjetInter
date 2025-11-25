include("data_loading.jl")

data = JSON.parsefile("Glouton/data.json")

v_q = Vector{String}() # questions
v_qc = Vector{Vector{Int}}() # caractéristiques par question
v_c = Vector{String}() # caractéristiques
v_uq = Vector{Vector{Int}}() # questions débloquées par caractéristique
nb_species = length(data["collection"])
species_matrix = Ref(BitMatrix(undef, 0, 0))
vect_species = Vector{String}(undef, nb_species)
    
fill_variables!(v_q, v_qc, v_c, v_uq, species_matrix, vect_species, data)

nb_carac = length(v_c)

for i in 1:nb_carac
    println("Caractéristique $i : $(v_c[i])")
end

for i in 1:length(v_q)
    println("Question $i : $(v_q[i])")
    println("Réponses de la question $i : $(v_c[v_qc[i]])")
end
