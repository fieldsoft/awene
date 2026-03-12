{-# LANGUAGE OverloadedStrings #-}
module Main where

import Web.Scotty
import Database.SQLite.Simple
      
data User = User { userId :: Int, username :: String } deriving (Show)

main :: IO ()
main = do
  conn <- open "test.db"
  
  execute_ conn
    "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT)"

  execute conn
    "INSERT INTO users (username) VALUES (?)" (Only ("noah" :: String))

  apiserver

  close conn

apiserver :: IO ()
apiserver = do
  putStrLn "Starting Server."
  scotty 3000 $ do
    get "/hello/:name" $ do
      name <- pathParam "name"
      text ("hello " <> name <> "!")
