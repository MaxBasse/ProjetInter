include("data_loading.jl")
include("Glouton/glouton.jl")
include("Glouton/fonctions_annexes.jl")

data = JSON.parsefile("Glouton/data.json")

v_q = Vector{String}() # questions
v_qc = Vector{Vector{Int}}() # caractéristiques par question
v_c = Vector{String}() # caractéristiques
v_uq = Vector{Vector{Int}}() # questions débloquées par caractéristique
nb_species = length(data["collection"])
sp_matrix = Ref(BitMatrix(undef, 0, 0))
vect_species = Vector{String}(undef, nb_species)
    
fill_variables!(v_q, v_qc, v_c, v_uq, sp_matrix, vect_species, data)

species_matrix = sp_matrix[]

nb_carac = length(v_c)

for i in 1:nb_carac
    println("Caractéristique $i : $(v_c[i])")
end

for i in 1:length(v_q)
    println("Question $i : $(v_q[i])")
    println("Réponses de la question $i : $(v_c[v_qc[i]])")
end

remaining_species=collect(1:length(vect_species))
asked_questions = Vector{Int}()

accessible_questions = Vector{Int}()
data = JSON.parsefile("Glouton/data.json")
for q in data["questions"]
    push!(accessible_questions, findfirst(==(q["title_q"]), v_q))
end


for answer_id in v_qc[35]
    new_remaining_species = remaining_species_update(species_matrix, remaining_species, answer_id)
    println("Answer ", answer_id, " → remaining_species = ", new_remaining_species)
end


new_species_matrix = copy(species_matrix)
for reponses in v_qc
    rowsums = vec(sum(new_species_matrix[:, reponses], dims=2))
    for i in axes(new_species_matrix, 1)
        if rowsums[i] == 0
            new_species_matrix[i, reponses] .= 1
        end
    end
end


#Application de l'algo
arbre=glouglouton(new_species_matrix, remaining_species, accessible_questions, v_qc, v_uq, asked_questions)
arbre_json=JSON.json(arbre, 4)

open("arbre_V1.json", "w") do f
    write(f, arbre_json)
end

