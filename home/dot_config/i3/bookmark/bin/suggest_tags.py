#!/usr/bin/env python
import sys
import requests
from bs4 import BeautifulSoup
import spacy
import re
from pathlib import Path

CACHE_DIR = Path.home() / ".cache" / "bookmark-tagger"
CACHE_DIR.mkdir(parents=True, exist_ok=True)

def clean_text(text):
    return re.sub(r'\s+', ' ', text).strip()

def get_cached_tags(url):
    cache_file = CACHE_DIR / f"{hash(url)}.tags"
    if cache_file.exists():
        return cache_file.read_text().strip()
    return None

def save_cached_tags(url, tags):
    cache_file = CACHE_DIR / f"{hash(url)}.tags"
    cache_file.write_text(','.join(tags))

try:
    url = sys.argv[1]
    
    # Check cache first
    cached = get_cached_tags(url)
    if cached:
        print(cached)
        sys.exit(0)
    
    # Fetch and parse
    response = requests.get(url, timeout=10)
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Remove unwanted elements
    for elem in soup(["script", "style", "meta", "nav", "footer"]):
        elem.decompose()
    
    # Try to find main content
    main = soup.find(['main', 'article']) or soup.find('body')
    text = clean_text(main.get_text()[:3000])
    
    # NLP processing
    nlp = spacy.load("en_core_web_sm")
    doc = nlp(text)
    
    # Extract relevant terms
    tags = set()
    for token in doc:
        if token.pos_ in ["NOUN", "PROPN"] and not token.is_stop and len(token.lemma_) > 2:
            tags.add(token.lemma_.lower())
    
    # Limit and cache results
    final_tags = sorted(tags)[:7]
    save_cached_tags(url, final_tags)
    print(','.join(final_tags))

except Exception as e:
    print("")
