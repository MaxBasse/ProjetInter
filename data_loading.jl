"""
    process_question!(vect_question::Vector{String}, vect_question_carac::Vector{Vector{Int}}, vect_carac::Vector{String}, vect_unlock_q::Vector{Vector{Int}}, q::Dict)

Traite une question extraite du JSON pour remplir les vecteurs de questions, caractéristiques, et questions débloquées

Cette fonction extrait le titre de la question et ses réponses, génère les caractéristiques uniques 
(format "Question :: Réponse"), et établit les liens entre les caractéristiques et les nouvelles questions qu'elles débloquent.
Elle s'appelle récursivement sur les sous-questions associées aux réponses.

# Arguments
- `vect_question::Vector{String}` : Liste de toutes les questions (mise à jour sur place).
- `vect_question_carac::Vector{Vector{Int}}` : Pour chaque index de question, stocke la liste des indices de caractéristiques associées.
- `vect_carac::Vector{String}` : Liste des caractéristiques uniques au format "Q :: R" (mise à jour sur place).
- `vect_unlock_q::Vector{Vector{Int}}` : Pour chaque index de caractéristique, stocke la liste des indices de questions débloquées.
- `q::Dict` : Le dictionnaire représentant la question courante (issue du JSON).

# Returns
- `Nothing` : La fonction modifie les vecteurs fournis en arguments.

# Exemple
    data = JSON.parsefile("data.json")

    v_q = Vector{String}() # questions
    v_qc = Vector{Vector{Int}}() # caractéristiques par question
    v_c = Vector{String}() # caractéristiques
    v_uq = Vector{Vector{Int}}() # questions débloquées par caractéristique

    for q in data["questions"]
       process_question!(v_q, v_qc, v_c, v_uq, q)
    end  
"""
function process_question!(vect_question::Vector{String}, vect_question_carac::Vector{Vector{Int}}, vect_carac::Vector{String}, vect_unlock_q::Vector{Vector{Int}}, q::Dict)::Nothing
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
                process_question!(vect_question, vect_question_carac, vect_carac, vect_unlock_q, subq)
                
                idQ_unlocked = findfirst(==(subq["title_q"]), vect_question)
                
                if !(idQ_unlocked in vect_unlock_q[idCarac])
                    push!(vect_unlock_q[idCarac], idQ_unlocked)
                end
            end
        end
    end 
end

"""
    extract_characteristics(choices, vect_carac::Vector{String})

Extrait les caractéristiques d'une espèce et retourne leur présence sous forme de vecteur booléen ou chaque index correspond à une caractéristique.

# Arguments
- `choices` : Première entrée "choices" de l'espèce à traiter (issue du JSON).
- `vect_carac::Vector{String}` : Liste des caractéristiques uniques au format "Q :: R".

# Returns
- `Vector{Bool}` : Vecteur booléen indiquant la présence des caractéristiques.

# Exemple
    data = JSON.parsefile("data.json")

    for (species) in enumerate(data["collection"])
        sp_carac = extract_characteristics(species["choices"], vect_carac)
    end 
"""
function extract_characteristics(choices, vect_carac::Vector{String}, nb_carac::Int)::BitVector
    d = falses(nb_carac) #Création d'une BitArray de taille nb_carac dont toutes les valeurs sont à false
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
                subdict = extract_characteristics(subqs, vect_carac, nb_carac) # recursivité pour faire de meme avec les questions imbriquées
                d = d .| subdict
            end
        end
    end
    return d
end


"""
    fill_variables!(vect_question::Vector{String}, vect_question_carac::Vector{Vector{Int}}, vect_carac::Vector{String}, vect_unlock_q::Vector{Vector{Int}}, species_matrix::BitMatrix, vect_species::Vector{String}, data::Dict)

Extrait les caractéristiques de toutes les espèces et remplit les vecteurs et matrices fournis à partir des données contenues dans data
# Arguments
- `vect_question::Vector{String}` : Liste de toutes les questions (mise à jour sur place).
- `vect_question_carac::Vector{Vector{Int}}` : Pour chaque index de question, stocke la liste des indices de caractéristiques associées.
- `vect_carac::Vector{String}` : Liste des caractéristiques uniques au format "Q :: R" (mise à jour sur place).
- `vect_unlock_q::Vector{Vector{Int}}` : Pour chaque index de caractéristique, stocke la liste des indices de questions débloquées.
- `species_matrix::BitMatrix` : Matrice binaire des espèces (mise à jour sur place).
- `vect_species::Vector{String}` : Liste des noms latins des espèces (mise à jour sur place).
- `data::Dict` : Dictionnaire contenant les données JSON complètes.

# Returns
- `Nothing` : Cette fonction modifie les vecteurs et matrices en place et ne retourne rien.

# Exemple
    data = JSON.parsefile("data.json")

    v_q = Vector{String}() # questions
    v_qc = Vector{Vector{Int}}() # caractéristiques par question
    v_c = Vector{String}() # caractéristiques
    v_uq = Vector{Vector{Int}}() # questions débloquées par caractéristique
    nb_species = length(data["collection"])
    species_matrix = falses(nb_species, nb_carac)
    vect_species = Vector{String}(undef, nb_species)
    
    fill_variables!(v_q, v_qc, v_c, v_uq, species_matrix, vect_species, data)
"""
function fill_variables!(vect_question::Vector{String}, vect_question_carac::Vector{Vector{Int}}, vect_carac::Vector{String}, vect_unlock_q::Vector{Vector{Int}}, species_matrix::BitMatrix, vect_species::Vector{String}, data::Dict)::Nothing
    for q in data["questions"]
       process_question!(vect_question, vect_question_carac, vect_carac, vect_unlock_q, q)
    end 

    nb_carac = length(vect_carac)

    for (i, species) in enumerate(data["collection"])
    latin = String(species["latin"])
    vect_species[i] = latin
    sp_carac = extract_characteristics(species["choices"], vect_carac, nb_carac)
        for j in 1:nb_carac
            species_matrix[i,j] = sp_carac[j]
        end
    end
end

