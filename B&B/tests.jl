include("separation.jl")

using Test


#test de MAJ_questions
"""
@testset "Test basique MAJ_questions" begin
    
    accessibles = ["q1", "q2"]
    posees = []
    current = "q1"
    answer = "yes"
    unlock = Dict("yes" => ["q3"])

    new_acc, new_pos = MAJ_questions(accessibles, posees, current, answer, unlock)

    @test new_acc == ["q2", "q3"]
    @test new_pos == ["q1"]

end
"""

#test de parcours_largeur
"""
# Arbre de test 
arbre_test = Dict{Any,Any}(
    "branches" => Dict{Any,Any}(
        "A" => Dict{Any,Any}(
            "branches" => Dict{Any,Any}(
                "B" => Dict("especes_restantes" => [1]),          # feuille avec 1 espèce
                "C" => Dict{Any,Any}(
                    "branches" => Dict{Any,Any}(
                        "D" => Dict("especes_restantes" => [2,3]),  # feuille avec 2 espèces → devrait être choisie
                        "E" => Dict("especes_restantes" => [4])
                    )
                )
            )
        ),
        "F" => Dict{Any,Any}(
            "branches" => Dict{Any,Any}(
                "G" => Dict("especes_restantes" => [5,6])        # une autre feuille avec plusieurs espèces
            )
        )
    )
)

# Test
@testset "Test parcours_largeur" begin
    feuille, chemin = parcours_largeur(arbre_test)

    # Vérifications
    @test haskey(feuille, "especes_restantes")
    @test length(feuille["especes_restantes"]) > 1
    @test chemin == ["F", "G"]  # la première feuille avec plusieurs espèces en largeur
    @test feuille["especes_restantes"] == [5,6]
end
"""

#test de MAJ_especes_restantes
"""
@testset "Test minimal MAJ_especes_restantes" begin

    # On crée un petit BitMatrix (4 espèces x 3 caractéristiques)
    df = BitMatrix([
        1 0 1;   # espèce 1
        1 1 0;   # espèce 2
        0 1 1;   # espèce 3
        0 0 1    # espèce 4
    ])

    remaining = [1,2,3,4]

    # Si la réponse correspond à la caractéristique 1
    new_remaining = MAJ_especes_restantes(df, remaining, 1)
    @test new_remaining == [1,2]  # seules espèces 1 et 2 ont la caractéristique 1

    # Test avec caractéristique 2
    new_remaining2 = MAJ_especes_restantes(df, remaining, 2)
    @test new_remaining2 == [2,3]

    # Test avec caractéristique 3
    new_remaining3 = MAJ_especes_restantes(df, remaining, 3)
    @test new_remaining3 == [1,3,4]

end
"""

#test de MAJ_cle_partielle
"""
# Mini-arbre avec 2 niveaux
arbre = Dict(
    "branches" => Dict(
        "root" => Dict(
            "especes_restantes" => [1,2,3],
            "questions_accessibles" => [1, 2],
            "questions_posees" => Int[],
            "profondeur" => 0,
            "branches" => Dict()
        )
    )
)

# Questions et réponses possibles
questions_answers = Dict(
    1 => [1, 2],
    2 => [3, 4]
)

# Déblocage de nouvelles questions après une réponse
question_unlock = Dict(
    1 => [2],
    2 => [],
    3 => [],
    4 => []
)

# Matrice espèces x caractéristiques (BitMatrix)
df_caract_species = BitMatrix([
    1 0 0;  # espèce 1
    1 1 0;  # espèce 2
    0 1 1   # espèce 3
])

# Chemin vers la feuille
chemin = ["root"]

# Question posée
q = 1

# Appel de la vraie fonction MAJ_cle_partielle
new_arbre = MAJ_cle_partielle(
    arbre,
    chemin,
    q,
    questions_answers,
    question_unlock,
    df_caract_species
)

# Vérifications simples
@testset "Test mini-arbre réel MAJ_cle_partielle" begin
    @test haskey(new_arbre["branches"]["root"], "branches")
    @test length(new_arbre["branches"]["root"]["branches"]) == 2
    @test all(x -> x in [1,2], keys(new_arbre["branches"]["root"]["branches"]))

    @test new_arbre["branches"]["root"]["branches"][1]["especes_restantes"] == [1,2]
    @test new_arbre["branches"]["root"]["branches"][2]["especes_restantes"] == [2,3]
end

"""


#test de separation
"""
# Mini-arbre pour test
arbre_test = Dict{Any,Any}(
    "branches" => Dict{Any,Any}(
        "root" => Dict{Any,Any}(
            "especes_restantes" => [1,2,3],
            "questions_accessibles" => [1, 2],
            "questions_posees" => Int[],
            "profondeur" => 0,
            "branches" => Dict{Any,Any}()
        )
    )
)

# Questions et réponses possibles
questions_answers = Dict(
    1 => [1,2],
    2 => [2,3]  
)

# Déblocage de nouvelles questions après une réponse
question_unlock = Dict(
    1 => [2],
    2 => [],
    3 => []
)

# Matrice espèces × caractéristiques (BitMatrix)
df_caract_species = BitMatrix([
    1 0 0;
    1 1 0;
    0 1 1
])

# Noeud initial
noeud_initial = Noeud(0, arbre_test)

# Test minimal pour separation
@testset "Test separation réel" begin
    nouveaux_noeuds = separation(noeud_initial, questions_answers, question_unlock, df_caract_species)
    
    # Vérifier qu'on a créé un noeud par question accessible
    @test length(nouveaux_noeuds) == 2

    for n in nouveaux_noeuds
        # La clé partielle contient des branches
        @test haskey(n.cle_partielle["branches"]["root"], "branches")
        for (rep, branch) in n.cle_partielle["branches"]["root"]["branches"]
            # Les espèces restantes doivent être dans [1,2,3]
            @test all(sp in [1,2,3] for sp in branch["especes_restantes"])
            # La profondeur doit avoir augmenté
            @test branch["profondeur"] == 1
            # La question courante doit être enregistrée
            @test any(q -> q in branch["questions_posees"], [1,2])
        end
    end
end
"""










