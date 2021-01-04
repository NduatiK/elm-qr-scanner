module Icons exposing (..)

import Element exposing (Attribute, Element, alpha, height, image, px, width)
import Html.Attributes


type alias IconBuilder msg =
    List (Attribute msg) -> Element msg


iconNamed : String -> List (Attribute msg) -> Element msg
iconNamed name attrs =
    image (alpha 0.54 :: Element.htmlAttribute (Html.Attributes.style "pointer-events" "none") :: attrs)
        { src = name, description = "" }


camera : List (Attribute msg) -> Element msg
camera attrs =
    iconNamed "images/camera.svg" (alpha 1 :: attrs)


cameraOff : List (Attribute msg) -> Element msg
cameraOff attrs =
    iconNamed "images/camera_off.svg" (alpha 1 :: attrs)


loading : List (Attribute msg) -> Element msg
loading attrs =
    iconNamed "images/loading.svg" (width (px 48) :: height (px 48) :: attrs)
