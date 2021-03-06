{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE OverlappingInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}


module Graphics.XHB.MappingState
    (  MappingState(..)
    , KeyMask
    , ButMask
    , ModMap
    , KeyMap
    , keyCodesOf
    , noPointer

    , MappingT(..)
    , runMappingT
    , MappingCtx(..)
    , getsMapping
    ) where


import Graphics.XHB
import Graphics.XHB.Monad
import Graphics.XHB.MappingState.Internal

import Data.Typeable

import Control.Monad.Except
import Control.Monad.Reader
import Control.Monad.State
import Control.Monad.Writer


newtype MappingT m a = MappingT { unMappingT :: StateT MappingState m a }
    deriving (Functor, Applicative, Monad, MonadIO, MonadTrans, Typeable)

deriving instance MonadX x m => MonadX x (MappingT m)

runMappingT :: MonadX x m => MappingT m a -> m a
runMappingT m = initMapState >>= evalStateT (unMappingT m)


-- Class --

class Monad m => MappingCtx m where
    getMapping :: m MappingState
    updateMapping :: MappingNotifyEvent -> m ()

instance MonadX x m => MappingCtx (MappingT m) where
    getMapping = MappingT get
    updateMapping ev = MappingT $ updateMapState ev >>= modify

instance (MappingCtx m, MonadTrans t, Monad (t m)) => MappingCtx (t m) where
    getMapping = lift getMapping
    updateMapping = lift . updateMapping


getsMapping :: MappingCtx m => (MappingState -> a) -> m a
getsMapping = flip fmap getMapping


-- MTL instances --

deriving instance MonadError e m => MonadError e (MappingT m)
deriving instance MonadReader r m => MonadReader r (MappingT m)
deriving instance MonadWriter w m => MonadWriter w (MappingT m)

instance MonadState s m => MonadState s (MappingT m) where
    state = lift . state
