from pymongo import MongoClient
import json

# Connect to MongoDB
client = MongoClient("mongodb://localhost:27017/")
db = client["skincare_app"]
collection = db["products"]

# Load JSON file
with open("skincare_products.json", "r", encoding="utf-8") as file:
    products = json.load(file)

# Insert into MongoDB
collection.insert_many(products)
print("Data inserted successfully!")
