using JSON

data = JSON.parsefile("data.json")


vect_carac = Vector{String}()
vect_question = Vector{String}()
vect_unlock_q = Vector{Vector{Int}}()

"""
Function used to process each question to fill the vector defined above

"""
function process_question(q)
    qtext = q["title_q"]
    if !(qtext in vect_question)
            push!(vect_question, qtext)
            push!(vect_unlock_q, Int[])
    end
    
    for a in q["answers"]
        atext = a["title_a"]
        pair =  "$qtext :: $atext"
        if !(pair in vect_carac)
            push!(vect_carac, pair)
        end
        # Récursivité sur les sous-questions 
        if haskey(a, "unlock_questions")    
            for subq in a["unlock_questions"]
                process_question(subq)
                idQ = findfirst(==(qtext), vect_question)
                idQ_unlocked = findfirst(==(subq["title_q"]), vect_question)
                if !(idQ_unlocked in vect_unlock_q[idQ])
                    push!(vect_unlock_q[idQ], idQ_unlocked)
                end
            end
        end
    end 
end

for q in data["questions"]
    process_question(q)
end

# Affichage des vecteurs
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

#min (|S1| + |S2| + ... + |Sn|) pour n questions
#min (max( |S1|, |S2|, ..., |Sn| )) pour n questions