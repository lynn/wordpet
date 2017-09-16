module SFX exposing (..)
import Audio

type SFX
  = Chirp
  | Beep

chirps : List String
chirps =
  [ "assets/sfx/10.mp3"
  , "assets/sfx/11.mp3"
  , "assets/sfx/12.mp3" ]

beeps : List String
beeps =
  [ "assets/sfx/20.mp3"
  , "assets/sfx/21.mp3"
  , "assets/sfx/22.mp3" ]

play : SFX -> Cmd msg
play sfx =
  case sfx of
    Chirp -> Audio.playOneOf chirps
    Beep -> Audio.playOneOf beeps
