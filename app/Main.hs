{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Control.Monad        (void, when)
import           Data.Text            (Text, isPrefixOf, pack, toLower)
import qualified Data.Text.IO         as TIO
import           UnliftIO.Concurrent

import           Configuration.Dotenv (defaultConfig, loadFile)
import           Discord
import qualified Discord.Requests     as R
import           Discord.Types
import           System.Environment   (getEnv)

-- | Replies "pong" to every message that starts with "ping"
main :: IO ()
main = do
    -- configuration.
    loadFile defaultConfig
    discordToken <- getEnv "DISCORD_TOKEN"

    -- run the bot.
    userFacingError <-
        runDiscord
            $ def
                { discordToken = "Bot " <> pack discordToken
                , discordOnEvent = eventHandler
                , discordOnLog = \s -> TIO.putStrLn s >> TIO.putStrLn ""
                } -- if you see OnLog error, post in the discord / open an issue
    TIO.putStrLn userFacingError

-- userFacingError is an unrecoverable error
-- put normal 'cleanup' code in discordOnEnd (see examples)

eventHandler :: Event -> DiscordHandler ()
eventHandler event = case event of
    MessageCreate m -> when (isPing m && not (fromBot m)) $ do
        void $ restCall (R.CreateReaction (messageChannelId m, messageId m) "eyes")
        threadDelay (2 * 10 ^ 6)
        void $ restCall (R.CreateMessage (messageChannelId m) "Pong!")
    _ -> return ()

fromBot :: Message -> Bool
fromBot = userIsBot . messageAuthor

isPing :: Message -> Bool
isPing = ("ping" `isPrefixOf`) . toLower . messageContent
