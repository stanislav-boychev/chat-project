module Main where

import System.IO
import Network.Socket
import Control.Concurrent
import Data.Hashable
import Control.Concurrent.Chan
import Control.Monad (liftM)
import Control.Monad.Fix (fix)

type Msg = String

main :: IO ()
main = do
  putStrLn "Starting "
  sock <- socket AF_INET Stream 0            -- create socket
  setSocketOption sock ReuseAddr 1           -- make socket immediately reusable - eases debugging.
  bind sock (SockAddrInet 9696 iNADDR_ANY)   -- listen on TCP port 9696.
  listen sock 10                              -- set a max of 2 queued connections
  chan <- newChan
  mainLoop sock chan 0                            -- unimplemented

mainLoop :: Socket -> Chan Msg -> Int -> IO ()
mainLoop sock chan n = do
    putStrLn $ "Sock Try No. " ++ (show n)
    conn <- accept sock
    forkIO (runConn conn chan (n+1))   -- split off each connection into its own thread
    mainLoop sock chan (n+1)


runConn :: (Socket, SockAddr) -> Chan Msg -> Int -> IO ()
runConn (sock, _) chan n = do
    let broadcast msg = writeChan chan msg
    let strN = show n
    hdl <- socketToHandle sock ReadWriteMode
    hSetBuffering hdl NoBuffering
    commLine <- dupChan chan

    -- fork off a thread for reading from the duplicated channel
    forkIO $ fix $ \loop -> do
        line <- readChan commLine
        hPutStrLn hdl line
        loop
    -- read lines from the socket and echo them back to the user
    fix $ \loop -> do
        line <- liftM init (hGetLine hdl)
        broadcast line
        loop
    hPutStrLn hdl ("Hello thread no. " ++ strN)
    hPutStrLn hdl $ show (hash strN)
    hPutStrLn hdl (strN ++ strN ++ strN ++ "!")
    hClose hdl


-- 1. Sockets configuration
-- 2. Understand Handles
-- 3. Solidify knowledge of fix and liftM


-- mainLoop :: Socket -> IO ()
-- mainLoop sock = do
--     conn <- accept sock     -- accept a connection and handle it
--     runConn conn            -- run our server's logic
--     mainLoop sock           -- repeat

-- runConn :: (Socket, SockAddr) -> IO ()
-- runConn (sock, _) = do
--     send sock "Hello!\n"
--     send sock "Bla!\n"
--     send sock "124!\n"
--     close sock

-- runConn :: (Socket, SockAddr) -> Int -> IO ()
-- runConn (sock, _) n = do
--     let strN = show n
--     hdl <- socketToHandle sock ReadWriteMode
--     hSetBuffering hdl NoBuffering
--     hPutStrLn hdl ("Hello thread no. " ++ strN)
--     hPutStrLn hdl $ show (hash strN)
--     hPutStrLn hdl (strN ++ strN ++ strN ++ "!")
--     hClose hdl
