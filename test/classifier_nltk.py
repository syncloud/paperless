from documents.classifier import DocumentClassifier

content = 'the quick brown foxes were jumping over the lazy dogs'
print(DocumentClassifier().preprocess_content(content, shared_cache=False))
