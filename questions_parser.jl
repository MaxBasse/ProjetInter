using JSON

data = JSON.parsefile("data.json")


vect_carac = Vector{String}()
vect_question = Vector{String}()
vect_unlock_q = Vector{Vector{Int}}()

"""
Function used to process each question to fill the vector defined above

"""



function process_question2(q)
    qtext = q["title_q"]
    if !(qtext in vect_question)
            push!(vect_question, qtext)
    end
    
    for a in q["answers"]
        atext = a["title_a"]
        key =  "$qtext :: $atext"
        if !(key in vect_carac)
            push!(vect_unlock_q, Int[])
            push!(vect_carac, key)
        end
        # Récursivité sur les sous-questions 
        if haskey(a, "unlock_questions")    
            for subq in a["unlock_questions"]
                process_question2(subq)
                idCarac = findfirst(==(key), vect_carac)
                idQ_unlocked = findfirst(==(subq["title_q"]), vect_question)
                if !(idQ_unlocked in vect_unlock_q[idCarac])
                    push!(vect_unlock_q[idCarac], idQ_unlocked)
                end
            end
        end
    end 
end

for q in data["questions"]
    process_question2(q)
end

println("Unlocked : \n")
for (i, questions) in enumerate(vect_unlock_q)
    println("Question ", i, " débloque les questions : ", questions)
    println("Question ", i, " est : ", vect_carac[i])
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