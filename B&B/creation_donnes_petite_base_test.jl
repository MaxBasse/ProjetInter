using JSON

include("BandB.jl")

data2 = JSON.parsefile(joinpath(@__DIR__, "petite_data_test.json"))


vect_carac = Vector{String}() # vector of characteristics of the form "question :: answer", the index of the characteristic in this vector is its id
vect_question = Vector{String}() # vector of questions of the form "question", the index of the question in this vector is its id
vect_unlock_q = Vector{Vector{Int}}() # vector of int vectors, for each characteristic (index in vect_carac), list of questions (index in vect_question) it unlocks
vect_question_carac = Vector{Vector{Int}}() # for each question (index in vect_question), list of characteristics (index in vect_carac) it 

"""
Function used to process each question to fill the vector defined above
    args:
        q : question to process
    returns:
        nothing, but updates the global vectors vect_carac, vect_question and vect_unlock_q

"""
function process_question(q)
    qtext = q["title_q"]
    if !(qtext in vect_question)
            push!(vect_question, qtext)
            push!(vect_question_carac, Int[])
    end
    
    for a in q["answers"]
        atext = a["title_a"]
        key =  "$qtext :: $atext"
        if !(key in vect_carac)
            push!(vect_unlock_q, Int[])
            push!(vect_carac, key)
        end

        idCarac = findfirst(==(key), vect_carac)
        idQ = findfirst(==(qtext), vect_question)

        if !(idCarac in vect_question_carac[idQ])
            push!(vect_question_carac[idQ], idCarac)
        end

        # Récursivité sur les sous-questions 
        if haskey(a, "unlock_questions")    
            for subq in a["unlock_questions"]
                process_question(subq)
                
                idQ_unlocked = findfirst(==(subq["title_q"]), vect_question)
                
                if !(idQ_unlocked in vect_unlock_q[idCarac])
                    push!(vect_unlock_q[idCarac], idQ_unlocked)
                end
            end
        end
    end 
end

for q in data2["questions"]
    process_question(q)
end






nb_species = length(data2["collection"])
nb_carac = length(vect_carac)
vect_species = Vector{String}(undef, nb_species)
species_matrix = falses(nb_species, nb_carac)

"""
Function used to extract the characteristics of a species
    args:
        choices : choices of the species to process
    returns:
        d : boolean vector of size nb_carac indicating which characteristics are present
"""
function extract_characteristics(choices)
    d = falses(nb_carac) 
    # dico de la forme : "question::réponse" → score.
    for choice in choices
        # recupere les caractéristiques de la question
        q = String(choice["id_question"])
        for opt in choice["options"]
            answer = String(opt[1])
            score  = Float64(opt[2])

            key = findfirst(==("$q :: $answer"), vect_carac)
            d[key] = score != 0.0

            # Sous-questions éventuelles
            subqs = opt[3]
            if !isempty(subqs)
                subdict = extract_characteristics(subqs)
                # recursivité pour faire de meme avec les questions imbriquées
                d = d .| subdict
            end
        end
    end
    return d
end

for (i, species) in enumerate(data2["collection"])
    latin = String(species["latin"])
    vect_species[i] = latin
    sp_carac = extract_characteristics(species["choices"])
    for j in 1:nb_carac
        species_matrix[i,j] = sp_carac[j]
    end
end

println(vect_unlock_q)
println(vect_species)
println(species_matrix)


# Test ensuite du B&B 

df_caract_species = species_matrix
question_unlock = vect_unlock_q
questions_answers = vect_question_carac


E_initial = collect(1:size(species_matrix)[1])

Qa_initial = Vector{Int}()
for q in data2["questions"]
    push!(Qa_initial, findfirst(==(q["title_q"]), vect_question))
end

println("---------------------  --------------------------------------")
println(question_unlock)
println("-----------------------------------------------------------")
println(questions_answers)

meilleure_solution, borne_sup = Branch_and_Bound(Qa_initial, E_initial, df_caract_species, question_unlock, questions_answers)
println("-----------------------------------------------------------")
println(meilleure_solution)
println("-----------------------------------------------------------")
println(borne_sup)


sol_glouton = glouglouton(df_caract_species, E_initial, Qa_initial, questions_answers, question_unlock)
# Calcul initial de la borne supérieure via le glouton
borne_sup = profondeur_arbre(sol_glouton)

println("-----------------------------------------------------------")
println(sol_glouton)
println("-----------------------------------------------------------")
println(borne_sup)

println(vect_question_carac)
println(species_matrix)

"""
#Application de l'algo
arbre= meilleure_solution
arbre_json=JSON.json(arbre, 4)

open("arbre_test.json", "w") do f
    write(f, arbre_json)
end



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



arbre_simplifie = simplifie_arbre(meilleure_solution)
json_str = JSON.json(arbre_simplifie, 4)

open("arbre_simplifie.json", "w") do f
    write(f, json_str)
end
"""
