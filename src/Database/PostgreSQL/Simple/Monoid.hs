module Database.PostgreSQL.Simple.Monoid (
    Qry,
    value,
    identifier
) where

    import Database.PostgreSQL.Simple
    import Database.PostgreSQL.Simple.ToField
    import Database.PostgreSQL.Simple.Types
    import Data.ByteString (ByteString)
    import Data.String
    import Data.Text (Text)

    data Qry = Qry {
        qry :: Query,
        fields :: [ Action ]
    }

    instance Monoid Qry where
        mempty = Qry {
                        qry = mempty,
                        fields = []
                    }
        mappend q1 q2 = Qry {
                                qry = mappend (qry q1) (qry q2),
                                fields = fields q1 ++ fields q2
                            }
        mconcat qs = Qry {
                            qry = mconcat (fmap qry qs),
                            fields = mconcat (fmap fields qs)
                        }


    instance IsString Qry where
        fromString s = Qry {
                            qry = fromString s,
                            fields = []
                        }

    value :: ToField a => a -> Qry
    value v = Qry {
                    qry = "?",
                    fields = [ toField v ]
                }

    identifier :: Text -> Qry
    identifier i = value . Identifier
