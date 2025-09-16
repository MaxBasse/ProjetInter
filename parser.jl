#Ok sympa premier comment
# jaime les pafs
"""
    leodum_qui_court(distance; track_length=400.0)

Retourne le nombre entier de tours complets parcourus par leodum
pour une `distance` (en mêmes unités que `track_length`).
"""
function leodum_qui_court(distance; track_length=400.0)
    if distance < 0
        throw(ArgumentError("distance doit être non-négative"))
    end
    return Int(floor(distance / track_length))
end
