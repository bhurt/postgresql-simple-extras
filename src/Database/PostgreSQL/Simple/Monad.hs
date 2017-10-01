{-# LANGUAGE FlexibleContexts     #-}
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE TypeFamilies         #-}
{-# LANGUAGE UndecidableInstances #-}

module Database.PostgreSQL.Simple.Monad (
    PGDBM(..),
    queryQ,
    executeQ,
    formatQueryQ,
    queryWithQ,
    copyQ,
    PGDBTransM(..),
    PGDBFoldM(..),
    foldQ,
    foldWithOptionsQ,
    forEachQ,
    foldWithQ,
    foldWithOptionsAndParserQ,
    forEachWithQ
) where

    import Control.Monad.IO.Class
    import Control.Monad.Trans.Control
    import Database.PostgreSQL.Simple.Monoid
    import Database.PostgreSQL.Simple.Types
    import Data.ByteString (ByteString)
    import Data.Int (Int64)
    import qualified Database.PostgreSQL.Simple as PSQL
    import qualified Database.PostgreSQL.Simple.Copy as PSQL
    import qualified Database.PostgreSQL.Simple.Cursor as PSQL
    import qualified Database.PostgreSQL.Simple.Internal as PSQL
    import qualified Database.PostgreSQL.Simple.LargeObjects as PSQL
    import qualified Database.PostgreSQL.Simple.Notification as PSQL
    import qualified Database.PostgreSQL.Simple.Transaction as PSQL
    import System.Posix.Types (CPid)

    class PGDBM m where
        connectPostgreSQL :: ByteString -> m PSQL.Connection
        close :: PSQL.Connection -> m ()
        connect :: PSQL.ConnectInfo -> m PSQL.Connection
        query :: (PSQL.ToRow q, PSQL.FromRow r) => PSQL.Connection -> Query -> q -> m [r]
        query_ :: PSQL.FromRow r => PSQL.Connection -> Query -> m [r]
        queryWith :: PSQL.ToRow q => PSQL.RowParser r -> PSQL.Connection -> Query -> q -> m [r]
        queryWith_ :: PSQL.RowParser r -> PSQL.Connection -> Query -> m [r]
        returning :: (PSQL.ToRow q, PSQL.FromRow r) => PSQL.Connection -> Query -> [q] -> m [r]
        returningWith :: PSQL.ToRow q => PSQL.RowParser r -> PSQL.Connection -> Query -> [q] -> m [r]
        execute :: PSQL.ToRow q => PSQL.Connection -> Query -> q -> m Int64
        execute_ :: PSQL.Connection -> Query -> m Int64
        executeMany :: PSQL.ToRow q => PSQL.Connection -> Query -> [q] -> m Int64
        begin :: PSQL.Connection -> m ()
        commit :: PSQL.Connection -> m ()
        rollback :: PSQL.Connection -> m ()
        formatMany :: PSQL.ToRow q => PSQL.Connection -> Query -> [q] -> m ByteString
        formatQuery :: PSQL.ToRow q => PSQL.Connection -> Query -> q -> m ByteString
        copy :: PSQL.ToRow params => PSQL.Connection -> Query -> params -> m ()
        copy_ :: PSQL.Connection -> Query -> m ()
        getCopyData :: PSQL.Connection -> m PSQL.CopyOutResult
        putCopyData :: PSQL.Connection -> ByteString -> m ()
        putCopyEnd :: PSQL.Connection -> m Int64
        putCopyError :: PSQL.Connection -> ByteString -> m ()
        declareCursor :: PSQL.Connection -> Query -> m PSQL.Cursor
        closeCursor :: PSQL.Cursor -> m ()
        loCreat :: PSQL.Connection -> m Oid 
        loCreate :: PSQL.Connection -> Oid -> m Oid 
        loImport :: PSQL.Connection -> FilePath -> m Oid 
        loImportWithOid :: PSQL.Connection -> FilePath -> Oid -> m Oid 
        loExport :: PSQL.Connection -> Oid -> FilePath -> m () 
        loOpen :: PSQL.Connection -> Oid -> PSQL.IOMode -> m PSQL.LoFd 
        loWrite :: PSQL.Connection -> PSQL.LoFd -> ByteString -> m Int 
        loRead :: PSQL.Connection -> PSQL.LoFd -> Int -> m ByteString 
        loSeek :: PSQL.Connection -> PSQL.LoFd -> PSQL.SeekMode -> Int -> m Int 
        loTell :: PSQL.Connection -> PSQL.LoFd -> m Int 
        loTruncate :: PSQL.Connection -> PSQL.LoFd -> Int -> m () 
        loClose :: PSQL.Connection -> PSQL.LoFd -> m () 
        loUnlink :: PSQL.Connection -> Oid -> m ()
        getNotification :: PSQL.Connection -> m PSQL.Notification
        getNotificationNonBlocking :: PSQL.Connection -> m (Maybe PSQL.Notification)
        getBackendPID :: PSQL.Connection -> m CPid
        beginLevel :: PSQL.IsolationLevel -> PSQL.Connection -> m ()
        beginMode :: PSQL.TransactionMode -> PSQL.Connection -> m ()
        newSavepoint :: PSQL.Connection -> m Savepoint
        releaseSavepoint :: PSQL.Connection -> Savepoint -> m ()
        rollbackToSavepoint :: PSQL.Connection -> Savepoint -> m ()
        rollbackToAndReleaseSavepoint :: PSQL.Connection -> Savepoint -> m ()

    liftIO1 :: MonadIO m => (a -> IO z) -> a -> m z
    liftIO1 f a = liftIO $ f a

    liftIO2 :: MonadIO m => (a -> b -> IO z) -> a -> b -> m z
    liftIO2 f a b = liftIO $ f a b

    liftIO3 :: MonadIO m => (a -> b -> c -> IO z) -> a -> b -> c -> m z
    liftIO3 f a b c = liftIO $ f a b c

    liftIO4 :: MonadIO m => (a -> b -> c -> d -> IO z) -> a -> b -> c -> d -> m z
    liftIO4 f a b c d = liftIO $ f a b c d

    instance MonadIO m => PGDBM m where
        connectPostgreSQL = liftIO1 PSQL.connectPostgreSQL
        close = liftIO1 PSQL.close
        connect = liftIO1 PSQL.connect
        query = liftIO3 PSQL.query
        query_ = liftIO2 PSQL.query_
        queryWith = liftIO4 PSQL.queryWith
        queryWith_ = liftIO3 PSQL.queryWith_
        returning = liftIO3 PSQL.returning
        returningWith = liftIO4 PSQL.returningWith
        execute = liftIO3 PSQL.execute
        execute_ = liftIO2 PSQL.execute_
        executeMany = liftIO3 PSQL.executeMany
        begin = liftIO1 PSQL.begin
        commit = liftIO1 PSQL.commit
        rollback = liftIO1 PSQL.rollback
        formatMany = liftIO3 PSQL.formatMany
        formatQuery = liftIO3 PSQL.formatQuery
        copy = liftIO3 PSQL.copy
        copy_ = liftIO2 PSQL.copy_
        getCopyData = liftIO1 PSQL.getCopyData
        putCopyData = liftIO2 PSQL.putCopyData
        putCopyEnd = liftIO1 PSQL.putCopyEnd
        putCopyError = liftIO2 PSQL.putCopyError
        declareCursor = liftIO2 PSQL.declareCursor
        closeCursor = liftIO1 PSQL.closeCursor
        loCreat = liftIO1 PSQL.loCreat
        loCreate = liftIO2 PSQL.loCreate
        loImport = liftIO2 PSQL.loImport
        loImportWithOid = liftIO3 PSQL.loImportWithOid
        loExport = liftIO3 PSQL.loExport
        loOpen = liftIO3 PSQL.loOpen
        loWrite = liftIO3 PSQL.loWrite
        loRead = liftIO3 PSQL.loRead
        loSeek = liftIO4 PSQL.loSeek
        loTell = liftIO2 PSQL.loTell
        loTruncate = liftIO3 PSQL.loTruncate
        loClose = liftIO2 PSQL.loClose
        loUnlink = liftIO2 PSQL.loUnlink
        getNotification = liftIO1 PSQL.getNotification
        getNotificationNonBlocking = liftIO1 PSQL.getNotificationNonBlocking
        getBackendPID = liftIO1 PSQL.getBackendPID
        beginLevel = liftIO2 PSQL.beginLevel
        beginMode = liftIO2 PSQL.beginMode
        newSavepoint = liftIO1 PSQL.newSavepoint
        releaseSavepoint = liftIO2 PSQL.releaseSavepoint
        rollbackToSavepoint = liftIO2 PSQL.rollbackToSavepoint
        rollbackToAndReleaseSavepoint = liftIO2 PSQL.rollbackToAndReleaseSavepoint

    queryQ :: (PGDBM m, PSQL.FromRow r) => PSQL.Connection -> Qry -> m [r]
    queryQ conn q
        | Prelude.null (fields q) = query_ conn (qry q)
        | otherwise               = query  conn (qry q) (fields q)

    executeQ :: PGDBM m => PSQL.Connection -> Qry -> m Int64
    executeQ conn q
        | Prelude.null (fields q) = execute_ conn (qry q)
        | otherwise               = execute  conn (qry q) (fields q)

    formatQueryQ :: PGDBM m => PSQL.Connection -> Qry -> m ByteString
    formatQueryQ conn q = formatQuery conn (qry q) (fields q)

    queryWithQ :: PGDBM m =>  PSQL.RowParser r -> PSQL.Connection -> Qry -> m [r]
    queryWithQ rp conn q 
        | Prelude.null (fields q) = queryWith_ rp conn (qry q)
        | otherwise               = queryWith  rp conn (qry q) (fields q)

    copyQ :: PGDBM m => PSQL.Connection -> Qry -> m ()
    copyQ conn q
        | Prelude.null (fields q) = copy_ conn (qry q)
        | otherwise               = copy  conn (qry q) (fields q)

    class PGDBM m => PGDBTransM m where
        withTransaction :: PSQL.Connection -> m a -> m a
        withSavepoint :: PSQL.Connection -> m a -> m a
        withTransactionLevel :: PSQL.IsolationLevel -> PSQL.Connection -> m a -> m a
        withTransactionMode :: PSQL.TransactionMode -> PSQL.Connection -> m a -> m a
        withTransactionModeRetry :: PSQL.TransactionMode -> (PSQL.SqlError -> Bool) -> PSQL.Connection -> m a -> m a
        withTransactionSerializable :: PSQL.Connection -> m a -> m a

    transIO1 :: MonadBaseControl IO m => (a -> IO (StM m z) -> IO (StM m z)) -> a -> m z -> m z
    transIO1 f a z = control $ \rib -> f a (rib z)

    transIO2 :: MonadBaseControl IO m => (a -> b -> IO (StM m z) -> IO (StM m z)) -> a -> b -> m z -> m z
    transIO2 f a b z = control $ \rib -> f a b (rib z)

    transIO3 :: MonadBaseControl IO m => (a -> b -> c -> IO (StM m z) -> IO (StM m z)) -> a -> b -> c -> m z -> m z
    transIO3 f a b c z = control $ \rib -> f a b c (rib z)

    instance (MonadIO m, MonadBaseControl IO m) => PGDBTransM m where
        withTransaction = transIO1 PSQL.withTransaction
        withSavepoint = transIO1 PSQL.withSavepoint
        withTransactionLevel = transIO2 PSQL.withTransactionLevel
        withTransactionMode = transIO2 PSQL.withTransactionMode
        withTransactionModeRetry = transIO3 PSQL.withTransactionModeRetry
        withTransactionSerializable = transIO1 PSQL.withTransactionSerializable

    class PGDBM m => PGDBFoldM m where
        type FoldM m :: * -> *
        fold :: (PSQL.FromRow row, PSQL.ToRow params) => PSQL.Connection -> Query -> params -> a -> (a -> row -> FoldM m a) -> m a
        fold_ :: PSQL.FromRow r => PSQL.Connection -> Query -> a -> (a -> r -> FoldM m a) -> m a 
        foldWithOptions :: (PSQL.FromRow row, PSQL.ToRow params) => PSQL.FoldOptions -> PSQL.Connection -> Query -> params -> a -> (a -> row -> FoldM m a) -> m a
        foldWithOptions_ :: PSQL.FromRow r => PSQL.FoldOptions -> PSQL.Connection -> Query -> a -> (a -> r -> FoldM m a) -> m a 
        forEach :: (PSQL.ToRow q, PSQL.FromRow r) => PSQL.Connection -> Query -> q -> (r -> FoldM m ()) -> m () 
        forEach_ :: PSQL.FromRow r => PSQL.Connection -> Query -> (r -> FoldM m ()) -> m () 
        foldWith :: PSQL.ToRow params => PSQL.RowParser row -> PSQL.Connection -> Query -> params -> a -> (a -> row -> FoldM m a) -> m a
        foldWith_ :: PSQL.RowParser r -> PSQL.Connection -> Query -> a -> (a -> r -> FoldM m a) -> m a
        foldWithOptionsAndParser :: PSQL.ToRow params => PSQL.FoldOptions -> PSQL.RowParser row -> PSQL.Connection -> Query -> params -> a -> (a -> row -> FoldM m a) -> m a
        foldWithOptionsAndParser_ :: PSQL.FoldOptions -> PSQL.RowParser r -> PSQL.Connection -> Query -> a -> (a -> r -> FoldM m a) -> m a 
        forEachWith :: PSQL.ToRow q => PSQL.RowParser r -> PSQL.Connection -> Query -> q -> (r -> FoldM m ()) -> m ()
        forEachWith_ :: PSQL.RowParser r -> PSQL.Connection -> Query -> (r -> FoldM m ()) -> m ()
        -- These two functions are hard to implement at the moment,
        -- for complicated reasons I'll admit I don't fully understand.
        -- In the future they will be.
        -- foldForward :: PSQL.FromRow r => PSQL.Cursor -> Int -> (a -> r -> FoldM m a) -> a -> m (Either a a)
        -- foldForwardWithParser :: PSQL.Cursor -> PSQL.RowParser r -> Int -> (a -> r -> FoldM m a) -> a -> m (Either a a)

    foldQ :: (PSQL.FromRow row, PGDBFoldM m) => PSQL.Connection -> Qry -> a -> (a -> row -> FoldM m a) -> m a
    foldQ conn q
        | Prelude.null (fields q) = fold_ conn (qry q)
        | otherwise               = fold  conn (qry q) (fields q)

    foldWithOptionsQ :: (PSQL.FromRow row, PGDBFoldM m) => PSQL.FoldOptions -> PSQL.Connection -> Qry -> a -> (a -> row -> FoldM m a) -> m a
    foldWithOptionsQ fo conn q
        | Prelude.null (fields q) = foldWithOptions_ fo conn (qry q)
        | otherwise               = foldWithOptions  fo conn (qry q) (fields q)

    forEachQ :: (PSQL.FromRow r, PGDBFoldM m) => PSQL.Connection -> Qry -> (r -> FoldM m ()) -> m () 
    forEachQ conn q
        | Prelude.null (fields q) = forEach_ conn (qry q)
        | otherwise               = forEach  conn (qry q) (fields q)

    foldWithQ :: PGDBFoldM m => PSQL.RowParser row -> PSQL.Connection -> Qry -> a -> (a -> row -> FoldM m a) -> m a
    foldWithQ rp conn q
        | Prelude.null (fields q) = foldWith_ rp conn (qry q)
        | otherwise               = foldWith  rp conn (qry q) (fields q)

    foldWithOptionsAndParserQ :: PGDBFoldM m => PSQL.FoldOptions -> PSQL.RowParser row -> PSQL.Connection -> Qry -> a -> (a -> row -> FoldM m a) -> m a
    foldWithOptionsAndParserQ fo rp conn q
        | Prelude.null (fields q) = foldWithOptionsAndParser_ fo rp conn (qry q)
        | otherwise               = foldWithOptionsAndParser  fo rp conn (qry q) (fields q)

    forEachWithQ :: PGDBFoldM m => PSQL.RowParser r -> PSQL.Connection -> Qry -> (r -> FoldM m ()) -> m ()
    forEachWithQ rp conn q
        | Prelude.null (fields q) = forEachWith_ rp conn (qry q)
        | otherwise               = forEachWith  rp conn (qry q) (fields q)

    foldIO :: MonadBaseControl IO m => (StM m a -> (StM m a -> r -> IO (StM m a)) -> IO (StM m a)) -> a -> (a -> r -> m a) -> m a
    foldIO f a g = control $ \rib -> do
                        i <- rib $ return a
                        f i $ \ sb r -> rib $ do
                                                    s <- restoreM sb
                                                    g s r

    instance (MonadIO m, MonadBaseControl IO m) => PGDBFoldM m where
        type FoldM m = m

        fold c q p = foldIO (PSQL.fold c q p)
        foldWithOptions o c q p = foldIO (PSQL.foldWithOptions o c q p)
        fold_ c q = foldIO (PSQL.fold_ c q)
        foldWithOptions_ o c q = foldIO (PSQL.foldWithOptions_ o c q) 

        forEach c q p f = foldIO (PSQL.fold c q p) () (const f)
        forEach_ c q f = foldIO (PSQL.fold_ c q) () (const f)

        foldWith rp c q p = foldIO (PSQL.foldWith rp c q p)
        foldWithOptionsAndParser o rp c q p = foldIO (PSQL.foldWithOptionsAndParser o rp c q p)
        foldWith_ rp c q  = foldIO (PSQL.foldWith_ rp c q)
        foldWithOptionsAndParser_ fo rp c q = foldIO (PSQL.foldWithOptionsAndParser_ fo rp c q)

        forEachWith rp c q p f = foldIO (PSQL.foldWith rp c q p) () (const f)
        forEachWith_ rp c q f = foldIO (PSQL.foldWith_ rp c q) () (const f)

