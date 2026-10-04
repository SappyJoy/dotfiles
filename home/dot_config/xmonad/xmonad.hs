-- xmonad: a tiling WM configured, and compiled, in Haskell. It arranges windows
-- itself: one master window plus a stack (Tall, Mirror Tall, Full; Super+space
-- cycles), so you rarely place anything by hand. xmonad's defaults plus
-- xmonad-contrib for the extras: the WM tour's shared keys on arrows, ten
-- workspaces, xmobar, notification-daemon and FILM. Super+Shift+r recompiles and
-- restarts (windows stay); `xmonad --recompile` checks this file.

import Control.Exception (evaluate)
import Control.Monad (when)
import System.Directory (createDirectoryIfMissing, doesFileExist, getHomeDirectory)
import System.Environment (lookupEnv)
import System.Exit (exitSuccess)
import System.FilePath (takeDirectory, (</>))

import XMonad
import XMonad.Actions.Navigation2D
import XMonad.Hooks.EwmhDesktops (ewmh, ewmhFullscreen)
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Layout.LayoutScreens (fixedLayout, layoutScreens)
import XMonad.Layout.NoBorders (noBorders)
import XMonad.Layout.ToggleLayouts (ToggleLayout (..), toggleLayouts)
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.SpawnOnce (spawnOnce)

-- FILM: one screen over the whole desk instead of one per monitor. The choice is
-- read at every (re)start; Super+Shift+f saves the other one and restarts.
filmFile :: IO FilePath
filmFile = do
    home <- getHomeDirectory
    st <- lookupEnv "XDG_STATE_HOME"
    return $ maybe (home </> ".local/state") id st </> "wm-tour" </> "film"

filmSaved :: IO Bool -- True: FILM (also when nothing is saved yet)
filmSaved = do
    f <- filmFile
    saved <- doesFileExist f
    if not saved
        then return True
        else do
            s <- readFile f
            _ <- evaluate (length s) -- read it all now: GHC locks a file while it's read
            return (take 1 (words s) /= ["off"])

filmToggle :: X ()
filmToggle = do
    film <- io filmSaved
    io $ do
        f <- filmFile
        createDirectoryIfMissing True (takeDirectory f)
        writeFile f (if film then "off\n" else "on\n")
    restart "xmonad" True

-- The X screen's size: all monitors together
rootSize :: IO (Dimension, Dimension)
rootSize = do
    d <- openDisplay ""
    let s = defaultScreen d
    -- evaluate now: lazily, these would read the display after closeDisplay frees it
    w <- evaluate (fromIntegral (displayWidth d s))
    h <- evaluate (fromIntegral (displayHeight d s))
    closeDisplay d
    return (w, h)

main :: IO ()
main = do
    film <- filmSaved
    (w, h) <- rootSize
    -- xmobar spans FILM; otherwise it sits on the first monitor. Each (re)start
    -- replaces the old bar itself: contrib's own cleanup looks for the command line
    -- as written, quotes included, so it never finds the FILM one.
    let xmobar
            | film = "xmobar -p 'Static { xpos = 0, ypos = 0, width = " ++ show w ++ ", height = 22 }'"
            | otherwise = "xmobar"
        bar =
            (statusBarProp xmobar (pure xmobarPP))
                { sbStartupHook = spawn ("pkill -xu \"$(id -u)\" xmobar; exec " ++ xmobar)
                , sbCleanupHook = pure ()
                }
    xmonad
        . ewmhFullscreen
        . ewmh
        . withNavigation2DConfig def
        . withEasySB bar defToggleStrutsKey
        $ def
            { modMask = mod4Mask
            , terminal = "kitty"
            , workspaces = map show [1 .. 10 :: Int]
            , layoutHook = toggleLayouts (noBorders Full) (layoutHook def)
            , startupHook = do
                spawnOnce "/usr/lib/notification-daemon-1.0/notification-daemon"
                spawnOnce "xset r rate 200 30"
                spawnOnce "xsetroot -cursor_name left_ptr"
                when film $ layoutScreens 1 (fixedLayout [Rectangle 0 0 w h])
            }
            `additionalKeysP` tourKeys

tourKeys :: [(String, X ())]
tourKeys =
    -- The tour's shared keys (they replace the stock Super+t, Super+Shift+q)
    [ ("M-t", spawn "kitty")
    , ("M-d", spawn "dmenu_run")
    , ("M-f", sendMessage ToggleLayout)
    , ("M-S-q", kill)
    , ("M-S-u", io exitSuccess)
    , ("M-S-r", spawn "xmonad --recompile && xmonad --restart")
    , ("M-S-f", filmToggle)
    , ("M-0", windows (W.greedyView "10"))
    , ("M-S-0", windows (W.shift "10"))
    , ("<XF86AudioRaiseVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ +5%")
    , ("<XF86AudioLowerVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ -5%")
    , ("<XF86AudioMute>", spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle")
    , -- Stock Super+t pushes a floating window back into the layout
      ("M-S-t", withFocused (windows . W.sink))
    ]
        ++ [ (mods ++ "<" ++ key ++ ">", action dir False)
           | (key, dir) <- [("Left", L), ("Right", R), ("Up", U), ("Down", D)]
           , (mods, action) <- [("M-", windowGo), ("M-S-", windowSwap)]
           ]
