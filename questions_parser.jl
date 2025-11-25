"""
    process_question!(vect_question, vect_question_carac, vect_carac, vect_unlock_q, q)

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
function process_question!(vect_question::Vector{String}, vect_question_carac::Vector{Vector{Int}}, vect_carac::Vector{String}, vect_unlock_q::Vector{Vector{Int}}, q::Dict)
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
#=
data = JSON.parsefile("data.json")
vect_carac = Vector{String}() # vector of characteristics of the form "question :: answer", the index of the characteristic in this vector is its id
vect_question = Vector{String}() # vector of questions of the form "question", the index of the question in this vector is its id
vect_unlock_q = Vector{Vector{Int}}() # vector of int vectors, for each characteristic (index in vect_carac), list of questions (index in vect_question) it unlocks
vect_question_carac = Vector{Vector{Int}}() # for each question (index in vect_question), list of characteristics (index in vect_carac) it possesses

for q in data["questions"]
    process_question!(vect_question, vect_question_carac, vect_carac, vect_unlock_q, q)
end
=#