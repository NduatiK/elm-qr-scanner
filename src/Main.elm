module Main exposing (Model, Msg, init, subscriptions, update, view)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font exposing (center)
import Element.Input as Input
import Html exposing (Html)
import Html.Attributes
import Icons
import Ports exposing (..)
import Url


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { code : String
    , problems : List Problem
    , cameraState : CameraState
    , openLinks : Bool
    }


type Problem
    = InvalidSerial
    | CameraOpenError
    | ServerError String (List String)
    | NotALink


type CameraState
    = CameraOpening
    | CameraClosed
    | CameraOpen
    | CameraClosing


init : flags -> ( Model, Cmd Msg )
init flags =
    ( Model "" [] CameraClosed True
    , Cmd.none
    )


type Msg
    = ToggleCamera
    | CameraOpened Bool
    | GotCameraNotFoundError
    | ReceivedQRCode String
    | ToggleOpenLinks


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleOpenLinks ->
            ( { model | openLinks = not model.openLinks }, Cmd.none )

        ToggleCamera ->
            if model.cameraState == CameraClosed then
                ( { model
                    | cameraState = CameraOpening
                    , problems = List.filter (\x -> x /= CameraOpenError) model.problems
                  }
                , Ports.initializeCamera ()
                )

            else
                ( model, Ports.disableCamera 0 )

        CameraOpened isActive ->
            ( { model
                | cameraState =
                    if isActive then
                        CameraOpen

                    else
                        CameraClosed
              }
            , Cmd.none
            )

        GotCameraNotFoundError ->
            let
                newError =
                    CameraOpenError

                -- Errors.toValidationError
                --     ( , "No webcam found" )
            in
            ( { model
                | problems =
                    if List.member newError model.problems then
                        model.problems

                    else
                        newError :: model.problems
              }
            , Cmd.none
            )

        ReceivedQRCode code ->
            let
                url =
                    Url.fromString code
            in
            ( { model
                | code = code
                , problems =
                    if url == Nothing then
                        if List.member NotALink model.problems then
                            model.problems

                        else
                            NotALink :: model.problems

                    else
                        List.filter (\x -> x /= NotALink) model.problems
              }
            , Cmd.batch
                [ Ports.disableCamera 500
                , Ports.setFrameFrozen False
                , case url of
                    Just aUrl ->
                        if model.openLinks then
                            Ports.rerouteTo (Url.toString aUrl)

                        else
                            Cmd.none

                    Nothing ->
                        Cmd.none
                ]
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.receiveCameraActive CameraOpened
        , Ports.scannedDeviceCode ReceivedQRCode
        , Ports.noCameraFoundError (\_ -> GotCameraNotFoundError)
        ]


view : Model -> Browser.Document Msg
view model =
    { title = "Scanner"
    , body =
        List.singleton <|
            Element.layout []
                -- column []
                -- [ text "New Document"
                -- , el [  ] none
                -- ]
                (Element.column
                    [ width fill, height fill, spacing 36 ]
                    [ if model.cameraState /= CameraClosed then
                        viewScanner model.cameraState

                      else
                        none
                    , column [ spacing 36, width shrink, height shrink, centerX, centerY ]
                        [ Input.button
                            [ padding 8
                            , centerY
                            , centerX
                            , Background.color (rgb 0 0 0)
                            , Border.rounded 8
                            , Border.width 1
                            ]
                            { label =
                                el []
                                    (if model.cameraState /= CameraClosed then
                                        Icons.cameraOff []

                                     else
                                        Icons.camera []
                                    )
                            , onPress = Just ToggleCamera
                            }
                        , Input.radioRow [ spacing 4, centerX ]
                            { onChange = always ToggleOpenLinks
                            , options =
                                [ Input.option True (text "Yes")
                                , Input.option False (text "No")
                                ]
                            , selected = Just model.openLinks
                            , label = Input.labelAbove [ centerX ] (text "Open links immediately")
                            }
                        , paragraph [ width (px 400), Border.width 1, padding 12 ] [ text model.code ]
                        ]

                    --
                    ]
                )
    }


viewScanner : CameraState -> Element Msg
viewScanner cameraState =
    let
        cameraStyle =
            if cameraState /= CameraClosed then
                [ Border.color (rgb255 97 165 145)
                , moveUp 2
                , Border.shadow { offset = ( 0, 12 ), blur = 20, size = 0, color = rgba255 0 0 0 0.3 }
                ]

            else
                [ Border.color (rgba255 197 197 197 0.5)
                ]
    in
    row [ centerX, centerY, spacing 20 ]
        [ el
            ([ width shrink
             , height shrink
             , Background.color (rgb 0 0 0)
             , Border.solid
             , Border.width 1
             , inFront
                (if cameraState == CameraClosing then
                    -- Animate closing
                    el [ width fill, height fill, Background.color (rgba 0 0 0 0.7) ]
                        (Icons.loading [ centerX, centerY, width (px 46), height (px 46) ])

                 else
                    none
                )
             ]
                ++ cameraStyle
            )
            (column [ width shrink ]
                [ html
                    (Html.canvas
                        [ Html.Attributes.id "camera-canvas"
                        , Html.Attributes.height 0
                        , Html.Attributes.width 0
                        , Html.Attributes.autoplay True
                        ]
                        []
                    )
                , el
                    ([ height (px 4)
                     , alignBottom
                     , alignLeft
                     , Background.color (rgb255 102 218 213)
                     ]
                        ++ (if cameraState == CameraOpen then
                                [ width fill, animatesAll ]

                            else
                                [ width (px 0), animatesAll ]
                           )
                    )
                    none
                ]
            )
        ]


animatesAll =
    Html.Attributes.style "transition" "all 250ms 0ms"
        |> htmlAttribute
