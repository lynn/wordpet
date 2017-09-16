module SFX exposing (..)
import Audio

type SFX
  = Chirp
  | Chomp

chirps : List String
chirps =
  [ "assets/sfx/tweet0.mp3"
  , "assets/sfx/tweet1.mp3"
  , "assets/sfx/tweet2.mp3" ]

chomps : List String
chomps =
  List.range 0 119
  |> List.map (\i -> "assets/sfx/chomp" ++ toString i ++ ".mp3")

play : SFX -> Cmd msg
play sfx =
  case sfx of
    Chirp -> Audio.playOneOf chirps
    Chomp -> Audio.playOneOf chomps
