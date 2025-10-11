include("questions_parser.jl")

#=
println("Vecteur des caractéristiques (question, réponse) :")
for (i, carac) in enumerate(vect_carac)
    println(carac, " -> Index: ", i)
end

println("\nVecteur des questions :")
for (i, question) in enumerate(vect_question)
    println(question, " -> Index: ", i)
end

println("\nUnlocked questions : ")
for (i, questions) in enumerate(vect_unlock_q)
    println("Question ", i, " débloque les questions : ", questions)
    println("Question ", i, " est : ", vect_question[i])
end
=#

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

nb_species = length(data["collection"])
nb_carac = length(vect_carac)
vect_species = Vector{String}(undef, nb_species)

species_matrix = falses(nb_species, nb_carac)
for (i, species) in enumerate(data["collection"])
    latin = String(species["latin"])
    vect_species[i] = latin
    sp_carac = extract_characteristics(species["choices"])
    for j in 1:nb_carac
        species_matrix[i,j] = sp_carac[j]
    end
end

println("\n")
println(findall(==(true), species_matrix[1,:]))
println("Nombre de caractéristiques pour l'espèce 1 : ", count(==(true), species_matrix[1,:]))
println("\n")

println("Espèce 1 ", vect_species[1], " a les caractéristiques suivantes : \n")
for i in findall(==(true), species_matrix[1,:])
    println("Caractéristique $i : ", vect_carac[i])
end


