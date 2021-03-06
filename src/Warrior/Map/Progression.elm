module Warrior.Map.Progression exposing
    ( Progression(..), ProgressionFunction
    , reachExitPoint, lastWarriorStanding
    , withRoundLimit
    )

{-| In this module you will find functions that define when a map has been won and lost. You can also define your own progression functions if you want to customize the game a bit.

@docs Progression, ProgressionFunction


# Pre-made progression functions

@docs reachExitPoint, lastWarriorStanding


# Additional limitations

@docs withRoundLimit

-}

import Warrior.History as History exposing (History)
import Warrior.Internal.Warrior as Player exposing (Warrior)
import Warrior.Map as Map exposing (Map)
import Warrior.Map.Tile as Tile


{-| There are three ways the course of the game can progress. We can _advance_ certain players to the next map. If there are no maps left, the advanced players are deemed the winners. The game can be lost, also known as _game over_, or the map can be _undecided_.
-}
type Progression
    = Advance (List Warrior)
    | GameOver
    | Undecided


{-| A function which receives information about the current map played, and decides what the game engine should do next. The function will be called at the end of every turn.
-}
type alias ProgressionFunction =
    List Warrior -> Map -> History -> Progression


{-| A progression function which advances all players when one has reached an exit point. The game is lost if all players are dead.
-}
reachExitPoint : ProgressionFunction
reachExitPoint players map _ =
    let
        anyoneReachedExit =
            List.any reachedExit players

        reachedExit player =
            Map.lookDown player map
                |> Tile.isExit

        allDead =
            players
                |> List.filter Player.alive
                |> List.isEmpty
    in
    if anyoneReachedExit then
        Advance players

    else if allDead then
        GameOver

    else
        Undecided


{-| A progression function that ends the game when only one warrior remains. Perfect for deathmatches.
-}
lastWarriorStanding : ProgressionFunction
lastWarriorStanding players _ _ =
    case players of
        [ victor ] ->
            Advance [ victor ]

        [] ->
            GameOver

        _ ->
            Undecided


{-| Takes in a progression function and ends the game if the original progression function is undecided, and a certain number of rounds has passed.
-}
withRoundLimit : Int -> ProgressionFunction -> ProgressionFunction
withRoundLimit roundLimit progFunc =
    \players map history ->
        case progFunc players map history of
            Undecided ->
                if History.roundsPlayed history >= roundLimit then
                    GameOver

                else
                    Undecided

            otherwise ->
                otherwise
