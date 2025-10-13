include("questions_parser.jl")

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
