{-# LANGUAGE TypeFamilies #-}

module Database.PostgreSQL.Simple.Monad (
    PostgresDBM(..),
    queryM,
    executeM,
    formatQueryM
) where

    import qualified Database.PostgreSQL.Simple as PSQL
    import Database.PostgreSQL.Simple.Types
    import Data.ByteString (ByteString)
    import Data.String
    import Data.Text (Text)
    import Database.PostgreSQL.Simple.Monoid

    class PostgresDBM m where
        connectPostgreSQL :: ByteString -> m Connection
        close :: Connection -> m ()
        connect :: ConnectInfo -> m Connection
        query :: (ToRow q, FromRow r) => Connection -> Query -> q -> m [r]
        query_ :: FromRow r => Connection -> Query -> m [r]
        queryWith :: ToRow q => RowParser r -> Connection -> Query -> q -> m [r]
        queryWith_ :: RowParser r -> Connection -> Query -> m [r]
        returning :: (ToRow q, FromRow r) => Connection -> Query -> [q] -> m [r]
        returningWith :: ToRow q => RowParser r -> Connection -> Query -> [q] -> m [r]
        execute :: ToRow q => Connection -> Query -> q -> m Int64
        execute_ :: Connection -> Query -> m Int64
        executeMany :: ToRow q => Connection -> Query -> [q] -> m Int64
        begin :: Connection -> m ()
        commit :: Connection -> m ()
        rollback :: Connection -> m ()
        formatMany :: ToRow q => Connection -> Query -> [q] -> m ByteString
        formatQuery :: ToRow q => Connection -> Query -> q -> m ByteString
        copy :: ToRow params => Connection -> Query -> params -> m ()
        copy_ :: Connection -> Query -> m ()
        getCopyData :: Connection -> m CopyOutResult
        putCopyData :: Connection -> ByteString -> m ()
        putCopyEnd :: Connection -> m Int64
        putCopyError :: Connection -> ByteString -> m ()
        declareCursor :: Connection -> Query -> m Cursor
        closeCursor :: Cursor -> m ()
        loCreat :: Connection -> m Oid 
        loCreate :: Connection -> Oid -> m Oid 
        loImport :: Connection -> FilePath -> m Oid 
        loImportWithOid :: Connection -> FilePath -> Oid -> m Oid 
        loExport :: Connection -> Oid -> FilePath -> m () 
        loOpen :: Connection -> Oid -> IOMode -> m LoFd 
        loWrite :: Connection -> LoFd -> ByteString -> m Int 
        loRead :: Connection -> LoFd -> Int -> m ByteString 
        loSeek :: Connection -> LoFd -> SeekMode -> Int -> m Int 
        loTell :: Connection -> LoFd -> m Int 
        loTruncate :: Connection -> LoFd -> Int -> m () 
        loClose :: Connection -> LoFd -> m () 
        loUnlink :: Connection -> Oid -> m ()
        getNotification :: Connection -> m Notification
        getNotificationNonBlocking :: Connection -> m (Maybe Notification)
        getBackendPID :: Connection -> m CPid
        beginLevel :: IsolationLevel -> Connection -> m ()
        beginMode :: TransactionMode -> Connection -> m ()
        newSavepoint :: Connection -> m Savepoint
        releaseSavepoint :: Connection -> Savepoint -> m ()
        rollbackToSavepoint :: Connection -> Savepoint -> m ()
        rollbackToAndReleaseSavepoint :: Connection -> Savepoint -> m ()

    liftIO1 :: MonadIO m => (a -> IO z) -> a -> m z
    liftIO1 f a = liftIO $ f a

    liftIO2 :: MonadIO m => (a -> b -> IO z) -> a -> b -> m z
    liftIO2 f a b = liftIO $ f a b

    liftIO3 :: MonadIO m => (a -> b -> c -> IO z) -> a -> b -> c -> m z
    liftIO3 f a b c = liftIO $ f a b c

    liftIO4 :: MonadIO m => (a -> b -> c -> d -> IO z) -> a -> b -> c -> d -> m z
    liftIO4 f a b c d = liftIO $ f a b c d

    instance MonadIO m => PostgresDBM m where
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
        putCopyData = liftIO1 PSQL.putCopyData
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

    queryM :: (PostgresDBM m, FromRow r) => Connection -> Qry -> m [r]
    queryM conn q = if Prelude.null (fields q)
                    then query_ conn (qry q)
                    else query conn (qry q) (fields q)

    executeM :: (PostgresDBM m, FromRow r) => Connection -> Qry -> m [r]
    executeM conn q = if Prelude.null (field q)
                        then execute_ conn (qry q)
                        else execute conn (qry q) (fields q)

    formatQueryM :: PostgresDBM m => Connection -> Qry -> m ByteString
    formatQueryM conn q = formatQuery conn (qry q) (fields q)

    class PostgresDBM m => PostgresDBTransM m where
        withTransaction :: Connection -> m a -> m a
        withSavepoint :: Connection -> m a -> m a
        withTransactionLevel :: IsolationLevel -> Connection -> m a -> m a
        withTransactionMode :: TransactionMode -> Connection -> m a -> m a
        withTransactionModeRetry :: TransactionMode -> (SqlError -> Bool) -> Connection -> m a -> m a
        withTransactionSerializable :: Connection -> m a -> m a

    transIO1 :: MonadBaseControl IO m :: (a -> IO z -> IO z) -> a -> m z -> m z
    transIO1 f a z = control $ \rib -> f a (rib z)

    transIO2 :: MonadBaseControl IO m :: (a -> b -> IO z -> IO z) -> a -> b -> m z -> m z
    transIO2 f a b z = control $ \rib -> f a b (rib z)

    transIO3 :: MonadBaseControl IO m :: (a -> b -> c -> IO z -> IO z) -> a -> b -> c -> m z -> m z
    transIO3 f a b c z = control $ \rib -> f a b c (rib z)

    instance MonadBaseControl IO m => PostgresDBTransM where
        withTransaction = transIO1 PSQL.withTransaction
        withSavepoint = transIO1 PSQL.withSavepoint
        withTransactionLevel = transIO2 PSQL.withTransactionLevel
        withTransactionMode = transIO2 PSQL.withTransactionMode
        withTransactionModeRetry = transIO3 PSQL.withTransactionModeRetry
        withTransactionSerializable = transIO1 PSQL.withTransactionSerializable

    class PostgresDBM m => PostgresDBFoldM m where
        type FoldM m :: * -> *
        fold :: (FromRow row, ToRow params) => Connection -> Query -> params -> a -> (a -> row -> FoldM m a) -> m a
        foldWithOptions :: (FromRow row, ToRow params) => FoldOptions -> Connection -> Query -> params -> a -> (a -> row -> FoldM m a) -> m a
        fold_ :: FromRow r => Connection -> Query -> a -> (a -> r -> FoldM m a) -> m a 
        foldWithOptions_ :: FromRow r => FoldOptions -> Connection -> Query -> a -> (a -> r -> FoldM m a) -> m a 
        forEach :: (ToRow q, FromRow r) => Connection -> Query -> q -> (r -> FoldM m ()) -> m () 
        forEach_ :: FromRow r => Connection -> Query -> (r -> FoldM m ()) -> m () 
        foldWith :: ToRow params => RowParser row -> Connection -> Query -> params -> a -> (a -> row -> FoldM m a) -> m a
        foldWithOptionsAndParser :: ToRow params => FoldOptions -> RowParser row -> Connection -> Query -> params -> a -> (a -> row -> FoldM m a) -> m a
        foldWith_ :: RowParser r -> Connection -> Query -> a -> (a -> r -> FoldM m a) -> m a
        foldWithOptionsAndParser_ :: FoldOptions -> RowParser r -> Connection -> Query -> a -> (a -> r -> FoldM m a) -> m a 
        forEachWith :: ToRow q => RowParser r -> Connection -> Query -> q -> (r -> FoldM m ()) -> m ()
        forEachWith_ :: RowParser r -> Connection -> Query -> (r -> FoldM m ()) -> m ()
        foldForward :: FromRow r => Cursor -> Int -> (a -> r -> FoldM m a) -> a -> m (Either a a)
        foldForwardWithParser :: Cursor -> RowParser r -> Int -> (a -> r -> FoldM m a) -> a -> m (Either a a)

    instance MonadBaseControl IO m => PostgresDBFoldM m where
        type FoldM m = m

        fold c q p x f = control $ \rib -> do
                                    init <- rib $ return x
                                    fold c q p init $ \ sb r -> rib $ do
                                                            s <- restoreM sb
                                                            f s r
