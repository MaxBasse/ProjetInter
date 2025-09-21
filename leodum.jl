#Chouette
# les foufous de sochaux
import Pkg
Pkg.add("JSON")
using JSON
donnees = JSON.parsefile("data.json")

println(donnees)
print(donnees["questions"][1]["title_q"])