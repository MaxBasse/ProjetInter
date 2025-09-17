

import Pkg
Pkg.add("JSON")
using JSON
donnees = JSON.parsefile("data.json")

#println(donnees)
println(donnees["questions"][1]["title_q"])
println(donnees["questions"][1]["answers"][1]["title_a"])
println(donnees["questions"][2]["title_q"])

#Parcourir le dictionnaire