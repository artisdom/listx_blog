{-# LANGUAGE OverloadedStrings #-}
import Control.Applicative ((<$>))
import Data.Monoid (mappend)
import Hakyll
import Blog.Custom (dateField')

main :: IO ()
main = hakyll $ do
	{- match "images/*" $ do
		route   idRoute
		compile copyFileCompiler
		-}

	match "css/*.css" $ do
		route   idRoute
		compile compressCssCompiler

	match "css/*.hs" $ do
		route $ setExtension "css"
		compile $ getResourceString >>= withItemBody (unixFilter "runghc" [])

	match (fromList ["about.md"]) $ do
		route   $ setExtension "html"
		compile $ pandocCompiler
			>>= loadAndApplyTemplate "templates/default.html" defaultContext
			>>= relativizeUrls

	match "post/*" $ do
		route $ setExtension "html"
		compile $ pandocCompiler
			>>= loadAndApplyTemplate "templates/post.html"    postCtx
			>>= loadAndApplyTemplate "templates/default.html" postCtx
			>>= relativizeUrls

	create ["archive.html"] $ do
		route idRoute
		compile $ do
			let
				archiveCtx =
					field "post" (\_ -> postList recentFirst) `mappend`
					constField "title" "Archive"              `mappend`
					defaultContext

			makeItem ""
				>>= loadAndApplyTemplate "templates/archive.html" archiveCtx
				>>= loadAndApplyTemplate "templates/default.html" archiveCtx
				>>= relativizeUrls


	match "index.html" $ do
		route idRoute
		compile $ do
			let
				indexCtx = field "post" $ \_ -> postList (take 3 . recentFirst)

			getResourceBody
				>>= applyAsTemplate indexCtx
				>>= loadAndApplyTemplate "templates/default.html" postCtx
				>>= relativizeUrls

	match "templates/*" $ compile templateCompiler

postCtx :: Context String
postCtx =
	dateField' "date" "%B %e, %Y" `mappend`
	defaultContext

postList :: ([Item String] -> [Item String]) -> Compiler String
postList sortFilter = do
	posts <- sortFilter <$> loadAll "post/*"
	itemTpl <- loadBody "templates/post-item.html"
	list <- applyTemplateList itemTpl postCtx posts
	return list
