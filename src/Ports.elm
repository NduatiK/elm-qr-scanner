port module Ports exposing (..)

-- OUTGOING


port initializeCamera : () -> Cmd msg


port disableCamera : Int -> Cmd msg


port setFrameFrozen : Bool -> Cmd msg


port rerouteTo : String -> Cmd msg



-- INCOMING


port qrCodeReceived : (String -> msg) -> Sub msg


port receiveCameraActive : (Bool -> msg) -> Sub msg


port scannedDeviceCode : (String -> msg) -> Sub msg


port noCameraFoundError : (Bool -> msg) -> Sub msg
