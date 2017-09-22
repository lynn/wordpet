module Msg exposing (..)
import Critter exposing (Critter)
import Time exposing (Time)

type Msg
  = Idle
  | TrackInput String
  | Feed
  | Pet
  | Vocalize VoiceType String
  | ChompTick Time
  | DizzyTick Time
  | ResetBabbleTimer Int
  | SetCritter Critter
  -- NLP ports
  | ReceivedSentences (List String)
  | ReceivedNormalize String

type VoiceType
  = Babble
  | Speech
