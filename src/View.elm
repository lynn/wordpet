module View exposing (..)

import Color
import Element exposing (..)
import Element.Attributes exposing (..)
import Html exposing (Html)
import Style exposing (..)
import Style.Border as Border
import Style.Color as Color
import Style.Font as Font
import String exposing (startsWith)

import Random.Pcg as Random exposing (Generator)

import Critter exposing (Critter)
import OldView
import Model exposing (..)
import Msg exposing (..)


{-| The type we use for identifiers for our styles.
-}
type Styles
  = None
  | Main
  | H1
  | CritterLayer


sansSerif : List Font
sansSerif =
  [ Font.font "helvetica"
  , Font.font "arial"
  , Font.font "sans-serif"
  ]


{-| First, we create a stylesheet.
Styles only deal with properties that are not related to layout, position, or size.
Generally all properties only have one allowed unit, which is usually px.
If you want to use something like em
-}
stylesheet : StyleSheet Styles v
stylesheet =
  Style.styleSheet
    [ style None [] -- It's handy to have a blank style
    , style Main
      [ Border.all 1 -- set all border widths to 1 px.
      , Color.text Color.white
      , Color.background (Color.rgb 125 119 168)
      , Color.border Color.lightGrey
      , Font.typeface sansSerif
      , Font.size 16
      , Font.lineHeight 1.3 -- line height, given as a ratio of current font size.
      ]
    , style H1
      [ Font.size 36
      ]
    , style CritterLayer []
    ]


-- A 300x240 element with one layer of the critter set as the background image.
-- Usage:  critterLayer "palette3" "body1"
critterLayer : String -> String -> Element Styles v Msg
critterLayer palette part =
  let
    wiggleAnim = "up4px 0.8s alternate infinite steps(2, end)"
    imageUrl = "url('assets/critter/" ++ palette ++ "/" ++ part ++ ".png')"
    isShadow = part |> startsWith "shadow"
    isLegs = part |> startsWith "legs"
  in el CritterLayer
    [ width (px 300)
    , height (px 240)
    , inlineStyle
      [ ("background-image", imageUrl)
      , ("background-size", "100%")
      , ("image-rendering", "pixelated")
      , ("animation", if isShadow || isLegs then "none" else wiggleAnim)
      , ("opacity", if isShadow then "0.75" else "1.0")
      ]
    ]
    empty


-- A 300x240 element containing critterLayers stacked on top of each other.
critterElement : Critter -> Element Styles v Msg
critterElement c =
  el None [ width (px 300), height (px 240) ] empty
    |> within (List.map (critterLayer c.palette) c.parts)


renderCritter : Model -> Element Styles v Msg
renderCritter model =
  let
    emote =
      case model.eating of
        Nothing -> identity
        Just e -> Critter.eating e.timer
  in
    critterElement (emote model.critter)


-- TODO: this should actually take the model and use it.
view : Model -> Html Msg
view model =
  Element.layout stylesheet <|
    full Main [center] <| column None [center] <|
      [ h1 H1 [paddingTop 20] (text "here are some babys to pet")
      , html (OldView.inputArea model)
      , html (OldView.speechBox model)
      , html (OldView.petButton model)
      , renderCritter model
      ]
