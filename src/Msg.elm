module Msg exposing (..)
import Critter exposing (Critter)
import Time exposing (Time)

type Msg
  = Idle
  | TrackInput String
  | Feed
  | Pet
  | Babble String
  | Speak String
  | ChompTick Time
  | ResetBabbleTimer Int
  | SetCritter Critter
  -- NLP ports
  | ReceivedSentences (List String)
  | ReceivedNormalize String
