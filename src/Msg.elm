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
  | DownloadModel
  | StartUpload
  -- ports
  | ReceivedSentences (List String)
  | ReceivedNormalize String
  | ReceivedFileContents String

type VoiceType
  = Babble
  | Speech
