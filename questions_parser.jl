using JSON

#data = JSON.parsefile("data.json")

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

for q in data["questions"]
    process_question(q)
end