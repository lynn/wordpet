module Msg exposing (..)
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
  -- NLP ports
  | ReceivedSentences (List String)
  | ReceivedNormalize String
