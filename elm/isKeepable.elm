module Main exposing (..)


dash =
    '-'


isKeepable character =
    character /= dash


withoutDashes str =
    String.filter isKeepable str
