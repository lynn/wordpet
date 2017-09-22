module SFX exposing (..)
import Audio

type SFX
  = None
  | Chirp
  | Chomp
  | Gulp
  | Hatch
  | Rattle
  | Screech

chirps : List String
chirps =
  List.range 0 12
  |> List.map (\i -> "assets/sfx/tweet" ++ toString i ++ ".mp3")

chomps : List String
chomps =
  List.range 1 119
  |> List.map (\i -> "assets/sfx/chomp" ++ toString i ++ ".mp3")

screeches : List String
screeches =
  List.range 0 9
  |> List.map (\i -> "assets/sfx/screech" ++ toString i ++ ".mp3")

play : SFX -> Cmd msg
play sfx =
  case sfx of
    None -> Cmd.none
    Chirp -> Audio.playOneOf chirps
    Chomp -> Audio.playOneOf chomps
    Gulp -> Audio.play "assets/sfx/gulp.mp3"
    Hatch -> Audio.play "assets/sfx/hatch.mp3"
    Rattle -> Audio.play "assets/sfx/rattle.mp3"
    Screech -> Audio.playOneOf screeches
